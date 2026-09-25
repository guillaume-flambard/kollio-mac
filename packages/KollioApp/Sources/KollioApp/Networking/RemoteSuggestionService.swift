import Foundation
import Security
import KollioCore

/// The API token lives in the Keychain, never in UserDefaults and never in the
/// bundle.
public enum TokenStore {
    public static let service = "dev.kollio.app"
    public static let account = "api-token"

    public enum Failure: Error { case keychain(OSStatus) }

    public static func save(_ token: String) throws {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw Failure.keychain(status) }
    }

    public static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// Talks to KollioServer. The document stays on this machine: every request
/// carries a scoped context and a base semantic revision, and every answer is a
/// proposed patch that the client validates again before showing it.
public struct RemoteSuggestionService: SuggestionService {
    public enum ClientError: Error, LocalizedError {
        case notConfigured
        case unauthorized
        case stale
        case rejected(String)
        case transport(String)
        case malformedResponse

        public var errorDescription: String? {
            switch self {
            case .notConfigured: return "No server configured"
            case .unauthorized: return "The server rejected the API token"
            case .stale: return "The document changed while the server was thinking"
            case .rejected(let reason): return reason
            case .transport(let detail): return "Could not reach the server: \(detail)"
            case .malformedResponse: return "The server answered something unexpected"
            }
        }
    }

    public let baseURL: URL
    private let token: String
    private let session: URLSession

    public init(baseURL: URL, token: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.token = token
        self.session = session
    }

    public var capabilities: SuggestionCapabilities {
        SuggestionCapabilities(
            intents: ProposalRequest.Intent.allCases,
            deterministic: false,
            requiresNetwork: true
        )
    }

    public func respond(to request: ProposalRequest, document: KollioDocument) async throws -> ProposalResponse {
        var scoped = request
        scoped.context = ContextBuilder().context(for: request, document: document)

        var urlRequest = URLRequest(url: baseURL.appendingPathComponent("v1/proposals"))
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder.kollioWire.encode(scoped)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw ClientError.transport(error.localizedDescription)
        }
        guard let http = response as? HTTPURLResponse else { throw ClientError.malformedResponse }
        return try decode(data, statusCode: http.statusCode, for: request, document: document)
    }

    /// Everything the client does with an answer, once it has it.
    ///
    /// Separated from the transport on purpose: the server is never trusted to
    /// be the only gate, and this step is the one the tests exercise.
    public func decode(
        _ data: Data,
        statusCode: Int,
        for request: ProposalRequest,
        document: KollioDocument
    ) throws -> ProposalResponse {
        switch statusCode {
        case 200...299:
            break
        case 401, 403:
            throw ClientError.unauthorized
        case 409:
            throw ClientError.stale
        default:
            let reason = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.reason ?? "HTTP \(statusCode)"
            throw ClientError.rejected(reason)
        }

        let decoded: ProposalResponse
        do {
            decoded = try JSONDecoder.kollioWire.decode(ProposalResponse.self, from: data)
        } catch {
            throw ClientError.malformedResponse
        }
        // The client validates the proposal again: the server is not trusted
        // to be the only gate.
        if let proposal = decoded.proposal {
            do {
                try ProposalValidator().validate(proposal, against: document, scope: request.scope)
            } catch {
                throw ClientError.rejected(String(describing: error))
            }
        }
        return decoded
    }

    /// Asks the server to forget an in-flight request, so a late answer is never
    /// mistaken for a live one.
    public func cancel(requestId: String) async {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/proposal-requests/\(requestId)"))
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: request)
    }

    public func liveCapabilities() async throws -> [String: String] {
        var request = URLRequest(url: baseURL.appendingPathComponent("v1/capabilities"))
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClientError.unauthorized
        }
        return try JSONDecoder().decode([String: String].self, from: data)
    }

    struct ErrorBody: Decodable {
        var reason: String
    }
}

/// The client builds its own context: the server never receives the document.
public struct ContextBuilder {
    public init() {}

    public func context(for request: ProposalRequest, document: KollioDocument) -> [ProposalRequest.ContextItem] {
        var ids: Set<ObjectID> = []
        for target in request.targetIds {
            ids.insert(target)
            for relationship in document.incidents(of: target) {
                ids.insert(relationship.from)
                ids.insert(relationship.to)
            }
        }
        return ids.compactMap { id in
            guard let object = document.object(id) else { return nil }
            return .init(
                objectID: object.id,
                kind: object.kind,
                text: object.text.text,
                lifecycle: object.lifecycle
            )
        }
        .sorted { $0.objectID.rawValue < $1.objectID.rawValue }
    }
}

extension JSONEncoder {
    public static var kollioWire: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    public static var kollioWire: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
