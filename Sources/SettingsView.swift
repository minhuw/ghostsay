import Cocoa
import SwiftUI

struct SettingsView: View {
    @StateObject private var serverManager = ServerManager.shared
    @State private var portString: String = ""
    @State private var availableIPs: [(ip: String, description: String, isPublic: Bool)] = []
    @State private var portValidationError: String? = nil
    @State private var showCopiedFeedback = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with Save & Restart button
            HStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "speaker.wave.2.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("GhostSay")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Text-to-Speech Server")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button("Save & Restart") {
                    saveAndRestart()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
            }

            // Network Settings section
            SettingsSection(title: "Network Settings") {
                VStack(alignment: .leading, spacing: 16) {
                    // IP Address and Port controls
                    HStack(alignment: .top, spacing: 16) {
                        // IP Address
                        VStack(alignment: .leading, spacing: 8) {
                            Text("IP Address")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            Picker(selection: $serverManager.selectedIP, label: EmptyView()) {
                                ForEach(availableIPs, id: \.ip) { ipInfo in
                                    Text(ipInfo.description)
                                        .foregroundColor(ipInfo.isPublic ? .orange : .primary)
                                        .tag(ipInfo.ip)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(minWidth: 200)
                        }

                        // Vertical separator
                        Rectangle()
                            .fill(Color.secondary.opacity(0.3))
                            .frame(width: 1, height: 60)

                        // Port
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Port")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.primary)

                            TextField("57630", text: $portString)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 100)
                                .onSubmit {
                                    validateAndSavePort()
                                }
                                .onChange(of: portString) { _ in
                                    validatePort()
                                }
                        }

                        Spacer()
                    }

                    // Endpoint display
                    HStack(spacing: 8) {
                        Text(apiEndpoint)
                            .font(.system(size: 13, weight: .regular, design: .monospaced))
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)

                        Spacer()

                        Button(action: copyEndpoint) {
                            HStack(spacing: 4) {
                                Image(systemName: showCopiedFeedback ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 12))
                                    .foregroundColor(showCopiedFeedback ? .green : .primary)
                                Text(showCopiedFeedback ? "Copied!" : "Copy")
                                    .font(.system(size: 12))
                                    .foregroundColor(showCopiedFeedback ? .green : .primary)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // Warnings section
                    VStack(alignment: .leading, spacing: 8) {
                        if let selectedIPInfo = availableIPs.first(where: { $0.ip == serverManager.selectedIP }),
                           selectedIPInfo.isPublic
                        {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 12))

                                Text("Warning: This IP address is publicly accessible from the internet")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        if let error = portValidationError {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 12))

                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(width: 450, height: 320)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            portString = String(serverManager.port)
            availableIPs = serverManager.getAvailableIPs()
        }
    }

    private func validatePort() {
        guard !portString.isEmpty else {
            portValidationError = nil
            return
        }

        if let port = Int(portString) {
            if port < 1024 || port > 65535 {
                portValidationError = "Port must be between 1024-65535"
            } else {
                portValidationError = nil
            }
        } else {
            portValidationError = "Invalid port number"
        }
    }

    private func validateAndSavePort() {
        validatePort()

        if portValidationError == nil {
            if let port = Int(portString), port >= 1024, port <= 65535 {
                serverManager.port = port
            }
        } else {
            // Reset to current valid port
            portString = String(serverManager.port)
        }
    }

    private var apiEndpoint: String {
        let port = portString.isEmpty ? String(serverManager.port) : portString
        return "http://\(serverManager.selectedIP):\(port)/say?text=Hello"
    }

    private func copyEndpoint() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(apiEndpoint, forType: .string)

        // Show feedback
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedFeedback = true
        }

        // Reset feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedFeedback = false
            }
        }
    }

    private func saveAndRestart() {
        // Validate port before saving
        validateAndSavePort()

        // Only proceed if no validation errors
        if portValidationError == nil {
            serverManager.restartApplication()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)

            content
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor)),
                )
        }
    }
}
