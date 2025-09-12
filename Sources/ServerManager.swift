import Cocoa
import Foundation
import Hummingbird
import HummingbirdFoundation
import Logging
import Network
import NIOCore

@MainActor
class ServerManager: ObservableObject {
    static let shared = ServerManager()

    @Published var isRunning = false
    @Published var port = 57630
    @Published var selectedIP = "127.0.0.1"
    @Published var lastError: String? = nil

    private var server: HBApplication?
    private let logger = Logger(label: "ghostsay.server")

    private init() {
        loadSettings()
    }

    func start() {
        guard !isRunning else { return }

        lastError = nil
        isRunning = true
        logger.info("Starting GhostSay server on port \(port)")

        Task {
            do {
                let app = HBApplication(configuration: .init(address: .hostname(selectedIP, port: port)))

                app.router.get("/say") { request in
                    await self.handleSayRequest(request)
                }

                server = app
                try await app.asyncRun()

            } catch {
                let errorMessage = self.formatError(error)
                logger.error("Failed to start server: \(error)")
                await MainActor.run {
                    self.isRunning = false
                    self.lastError = errorMessage
                }
            }
        }
    }

    private func formatError(_ error: Error) -> String {
        let errorString = error.localizedDescription
        if errorString.contains("Address already in use") || errorString.contains("errno: 48") {
            return "Port \(port) is already in use. Try a different port in Settings."
        }
        return "Failed to start server: \(errorString)"
    }

    func stop() {
        guard isRunning else { return }

        server?.stop()
        server = nil
        isRunning = false
        lastError = nil

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

    func executeSayCommand(text: String) async -> Bool {
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
        text.replacingOccurrences(of: "&", with: "and")
            .replacingOccurrences(of: "`", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ";", with: "")
            .replacingOccurrences(of: "|", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getAvailableIPs() -> [(ip: String, description: String, isPublic: Bool)] {
        var addresses: [(String, String, Bool)] = []

        // Add localhost
        addresses.append(("127.0.0.1", "Localhost (127.0.0.1)", false))

        // Get network interfaces
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else {
            return addresses
        }
        defer { freeifaddrs(ifaddr) }

        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }

            guard let interface = ptr?.pointee,
                  let addrPtr = interface.ifa_addr else { continue }

            // Handle both IPv4 and IPv6 (focus on IPv4 for now)
            guard addrPtr.pointee.sa_family == UInt8(AF_INET) else { continue }

            let addr = addrPtr.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            let ip = String(cString: inet_ntoa(addr.sin_addr))

            let interfaceName = String(cString: interface.ifa_name)

            // Skip loopback and link-local
            if ip.hasPrefix("127.") || ip.hasPrefix("169.254.") { continue }
            let interfaceType = getInterfaceType(interfaceName)
            let isPublic = !isPrivateIP(ip)

            let description = createInterfaceDescription(interfaceName: interfaceName,
                                                         interfaceType: interfaceType,
                                                         ip: ip,
                                                         isPublic: isPublic)

            addresses.append((ip, description, isPublic))
        }

        // Sort addresses: localhost first, then private, then public
        addresses.sort { (first: (String, String, Bool), second: (String, String, Bool)) in
            if first.0 == "127.0.0.1" { return true }
            if second.0 == "127.0.0.1" { return false }
            if !first.2, second.2 { return true } // Private before public
            if first.2, !second.2 { return false }
            return first.1 < second.1 // Sort by description
        }

        return addresses
    }

    private func getInterfaceType(_ interfaceName: String) -> String {
        switch interfaceName.lowercased() {
        case let name where name.starts(with: "tailscale") || name.starts(with: "utun"):
            "Tailscale"
        case let name where name.starts(with: "en"):
            "Ethernet"
        case let name where name.starts(with: "wi"):
            "WiFi"
        case let name where name.starts(with: "bridge"):
            "Bridge"
        case let name where name.starts(with: "vbox") || name.starts(with: "vmnet"):
            "Virtual"
        case let name where name.starts(with: "docker"):
            "Docker"
        default:
            "Network"
        }
    }

    private func createInterfaceDescription(interfaceName: String, interfaceType: String, ip: String, isPublic: Bool) -> String {
        let publicWarning = isPublic ? " ⚠️ Public" : ""
        let typeLabel = interfaceType != "Network" ? " (\(interfaceType))" : ""

        return "\(interfaceName)\(typeLabel) - \(ip)\(publicWarning)"
    }

    private func isPrivateIP(_ ip: String) -> Bool {
        ip.hasPrefix("192.168.") ||
            ip.hasPrefix("10.") ||
            (ip.hasPrefix("172.") && isInRange172(ip)) ||
            ip.hasPrefix("100.") // Tailscale CGNAT range
    }

    private func isInRange172(_ ip: String) -> Bool {
        let components = ip.split(separator: ".")
        if components.count >= 2,
           let second = Int(components[1])
        {
            return second >= 16 && second <= 31
        }
        return false
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard
        port = defaults.integer(forKey: "GhostSay.port") != 0 ? defaults.integer(forKey: "GhostSay.port") : 57630
        selectedIP = defaults.string(forKey: "GhostSay.selectedIP") ?? "127.0.0.1"
    }

    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(port, forKey: "GhostSay.port")
        defaults.set(selectedIP, forKey: "GhostSay.selectedIP")
        defaults.synchronize()
    }

    func restartApplication() {
        saveSettings()

        // Stop server if running
        if isRunning {
            stop()
        }

        // Get the current executable path
        let executablePath = Bundle.main.executablePath ?? ProcessInfo.processInfo.arguments[0]

        logger.info("Attempting to restart with path: \(executablePath)")

        // Launch new instance and terminate current one
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                _ = try Process.run(URL(fileURLWithPath: executablePath), arguments: []) { _ in }
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            } catch {
                self.logger.error("Failed to restart application: \(error)")
                // If restart fails, just show an alert and continue
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Restart Required"
                    alert.informativeText = "Settings have been saved. Please manually restart the application to apply changes."
                    alert.alertStyle = .informational
                    alert.runModal()
                }
            }
        }
    }
}
