import Foundation
import Vapor
import KollioCore

/// The HTTP surface. Small on purpose: the client owns the document, the server
/// answers with a proposed patch.
public struct KollioServer: Sendable {
    public let configuration: ServerConfiguration
    public let service: ProposalService
    public let authenticator: BearerAuthenticator
    public let gate: RequestGate
    public let registry: RequestRegistry

    public init(
        configuration: ServerConfiguration,
        provider: (any LLMProvider)? = nil
    ) {
        self.configuration = configuration
        let resolved = provider ?? Self.makeProvider(configuration)
        self.service = ProposalService(provider: resolved, timeout: configuration.providerTimeout)
        self.authenticator = BearerAuthenticator(token: configuration.apiToken)
        self.gate = RequestGate(limit: configuration.maxConcurrentRequests)
        self.registry = RequestRegistry()
    }

    /// Offline by default. The remote provider only exists when a key does.
    static func makeProvider(_ configuration: ServerConfiguration) -> any LLMProvider {
        if configuration.groqIsEnabled {
            return GroqProvider(apiKey: configuration.groqAPIKey, model: configuration.groqModel)
        }
        return DemoProvider()
    }

    public func configure(_ app: Application) throws {
        app.routes.defaultMaxBodySize = "256kb"
        try routes(app)
    }

    public func routes(_ app: Application) throws {
        // Liveness and readiness are open: they must answer before any token is
        // known, and they reveal nothing.
        app.get("health", "live") { _ in
            return ["status": "ok"]
        }
        app.get("health", "ready") { req async throws -> [String: String] in
            _ = try authenticator.authenticate(req)
            let provider = service.provider
            return [
                "status": "ready",
                "provider": provider.name,
                "providerEnabled": String(provider.isEnabled)
            ]
        }

        let v1 = app.grouped("v1")
        v1.get("capabilities") { req throws -> [String: String] in
            _ = try authenticator.authenticate(req)
            return [
                "intents": ProposalRequest.Intent.allCases.map(\.rawValue).joined(separator: ","),
                "generator": service.provider.name,
                "requiresNetwork": String(!service.provider.name.hasPrefix("demo"))
            ]
        }

        v1.post("proposals") { req async throws -> Response in
            _ = try authenticator.authenticate(req)
            let body = try req.content.decode(ProposalRequest.self, using: JSONDecoder.kollio)

            guard await gate.acquire() else {
                throw Abort(.tooManyRequests, reason: "A request is already running for this client")
            }
            await registry.open(body.requestId)
            defer { gate.releaseTask() }

            let document = body.snapshot
            do {
                // No document is held by the server: the request carries the
                // slice to reason about, and a request without one is refused
                // rather than answered against a stand-in document.
                guard let document else {
                    throw ProposalService.Rejection.invalidSnapshot("the request carried no document snapshot")
                }
                let response = try await service.respond(to: body, snapshot: document)
                await registry.finish(body.requestId)
                let data = try JSONEncoder.kollio.encode(response)
                return Response(status: .ok, headers: ["Content-Type": "application/json"], body: .init(data: data))
            } catch {
                await registry.finish(body.requestId)
                throw Self.map(error)
            }
        }

        v1.delete("proposal-requests", ":requestId") { req async throws -> [String: String] in
            _ = try authenticator.authenticate(req)
            let id = try req.parameters.require("requestId")
            await registry.cancel(id)
            return ["status": "cancelled", "requestId": id]
        }
    }

    /// The test surface and the local development surface share one document:
    /// the client sends the slice it wants reasoned about, never a whole store.
    static func map(_ error: Error) -> Error {
        switch error {
        case ProposalService.Rejection.unknownTarget(let id):
            return Abort(.badRequest, reason: "Unknown target \(id)")
        case ProposalService.Rejection.stale(let revision, _):
            return Abort(.conflict, reason: "Document moved on to revision \(revision)")
        case ProposalService.Rejection.providerMalformed(let detail):
            return Abort(.unprocessableEntity, reason: "Provider returned an invalid proposal: \(detail)")
        case ProposalService.Rejection.providerRefused(let reason):
            return Abort(.unprocessableEntity, reason: "Provider refused: \(reason)")
        case ProposalService.Rejection.providerUnavailable:
            return Abort(.serviceUnavailable, reason: "Provider unavailable")
        case ProposalService.Rejection.timedOut:
            return Abort(.gatewayTimeout, reason: "Provider timed out")
        case ProposalService.Rejection.invalidSnapshot(let detail):
            // A bad snapshot is the client's problem to fix, so it is a 400 and
            // not a server fault.
            return Abort(.badRequest, reason: "Invalid document snapshot: \(detail)")
        default:
            return error
        }
    }
}

extension RequestGate {
    /// Release from a synchronous context.
    nonisolated func releaseTask() {
        let gate = self
        Task { await gate.release() }
    }
}

extension JSONEncoder {
    /// The wire format: pretty printed, sorted keys, ISO 8601 timestamps, so a
    /// response can be read by a human and by another model.
    public static var kollio: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

extension JSONDecoder {
    public static var kollio: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
