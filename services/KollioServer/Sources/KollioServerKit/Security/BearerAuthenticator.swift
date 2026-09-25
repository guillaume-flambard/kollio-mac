import Foundation
import Vapor
import KollioCore

/// Opaque bearer token between the macOS client and this API.
///
/// Not an accounts system: one private token, configured or generated per
/// process, compared in constant time. Nothing is stored in a database.
public struct BearerAuthenticator: Sendable {
    private let token: String

    public init(token: String) {
        self.token = token
    }

    public enum Failure: Error, AbortError {
        case missing
        case invalid

        public var status: HTTPResponseStatus { .unauthorized }

        public var reason: String {
            switch self {
            case .missing: return "Missing bearer token"
            case .invalid: return "Invalid bearer token"
            }
        }
    }

    public func authenticate(_ request: Request) throws -> String {
        guard let header = request.headers.first(name: .authorization) else {
            throw Failure.missing
        }
        let parts = header.split(separator: " ", maxSplits: 1).map(String.init)
        guard parts.count == 2, parts[0].lowercased() == "bearer" else {
            throw Failure.missing
        }
        guard constantTimeEquals(parts[1], token) else {
            throw Failure.invalid
        }
        return parts[1]
    }

    /// Comparison that does not leak the position of the first difference.
    private func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let left = Array(lhs.utf8)
        let right = Array(rhs.utf8)
        var difference = UInt8(lhs.utf8.count ^ rhs.utf8.count)
        let count = Swift.max(left.count, right.count)
        for index in 0..<count {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            difference |= a ^ b
        }
        return difference == 0
    }
}
