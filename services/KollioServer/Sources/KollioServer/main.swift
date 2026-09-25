import Foundation
import Vapor
import KollioServerKit

// The backend is a separate process from the macOS application. It is not
// authoritative for the local document: the client owns it and sends a scoped
// context with every request.
@main
struct KollioServerMain {
    static func main() async throws {
        var environment = try Environment.detect()
        try LoggingSystem.bootstrap(from: &environment)

        let configuration = ServerConfiguration()
        let app = try await Application.make(environment)
        let server = KollioServer(configuration: configuration)

        if configuration.tokenWasGenerated {
            app.logger.info("""
            No KOLLIO_API_TOKEN in the environment: generated one for this process.
            Token: \(configuration.apiToken)
            """)
        }
        app.logger.info("KollioServer starting on \(configuration.bindAddress):\(configuration.port)")
        app.logger.info("Provider: \(configuration.groqIsEnabled ? "groq (\(configuration.groqModel))" : "demo (offline)")")

        try server.configure(app)
        // `app.run()` boots the event loop and blocks until shutdown.
        try await app.execute()
    }
}
