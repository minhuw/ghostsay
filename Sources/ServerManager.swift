import Foundation
import Hummingbird
import HummingbirdFoundation
import Logging
import NIOCore

@MainActor
class ServerManager: ObservableObject {
    static let shared = ServerManager()

    @Published var isRunning = false
    @Published var port = 5000

    private var server: HBApplication?
    private let logger = Logger(label: "ghostsay.server")

    private init() {}

    func start() {
        guard !isRunning else { return }

        Task {
            do {
                let app = HBApplication(configuration: .init(address: .hostname("127.0.0.1", port: port)))

                app.router.get("/say") { request in
                    await self.handleSayRequest(request)
                }

                server = app
                try await app.asyncRun()

            } catch {
                logger.error("Failed to start server: \(error)")
                await MainActor.run {
                    self.isRunning = false
                }
            }
        }

        isRunning = true
        logger.info("GhostSay server started on port \(port)")
    }

    func stop() {
        guard isRunning else { return }

        server?.stop()
        server = nil
        isRunning = false

        logger.info("GhostSay server stopped")
    }

    private func handleSayRequest(_ request: HBRequest) async -> String {
        guard let text = request.uri.queryParameters.get("text", as: String.self) else {
            return #"{"error":"Missing or invalid 'text' parameter"}"#
        }

        let success = await executeSayCommand(text: text)

        if success {
            return #"{"success":true,"message":"Text spoken successfully"}"#
        } else {
            return #"{"success":false,"message":"Failed to execute say command"}"#
        }
    }

    private func executeSayCommand(text: String) async -> Bool {
        let sanitizedText = sanitizeText(text)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = [sanitizedText]

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            logger.error("Failed to execute say command: \(error)")
            return false
        }
    }

    private func sanitizeText(_ text: String) -> String {
        return text.replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ";", with: "")
            .replacingOccurrences(of: "|", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
