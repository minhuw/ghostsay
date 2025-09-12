import Cocoa
import SwiftUI

struct MenuBarView: View {
    @StateObject private var serverManager = ServerManager.shared
    @Environment(\.openWindow) private var openWindow
    @State private var dismissTimer: Timer?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status section - using HStack to eliminate vertical spacing
            HStack(alignment: .top, spacing: 0) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6) // Align with first text line

                VStack(alignment: .leading, spacing: 0) {
                    Text(serverStatusTitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineSpacing(0)
                        .padding(.leading, 10)

                    // Always reserve space for IP address line to prevent jumping
                    Text(serverManager.isRunning ? "\(serverManager.selectedIP):\(String(serverManager.port))" : " ")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineSpacing(0)
                        .padding(.leading, 10)
                        .opacity(serverManager.isRunning ? 1.0 : 0.0)

                    if let error = serverManager.lastError {
                        Text(error)
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                            .lineLimit(2)
                            .padding(.leading, 10)
                            .padding(.top, 2)
                    }
                }

                Spacer()

                // Always reserve space for copy button to prevent jumping
                Button(action: copyEndpoint) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Copy endpoint URL")
                .opacity(serverManager.isRunning ? 1.0 : 0.0)
                .disabled(!serverManager.isRunning)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)

            // Action buttons
            VStack(spacing: 2) {
                MenuButton(
                    icon: serverManager.isRunning ? "stop.circle" : "play.circle",
                    title: serverToggleText,
                    action: toggleServer,
                )

                MenuButton(
                    icon: "mic.circle",
                    title: "Test Voice",
                    action: testVoice,
                )

                Divider()
                    .padding(.horizontal, 16)

                MenuButton(
                    icon: "gear",
                    title: "Settings...",
                    action: { openWindow(id: "settings") },
                )

                Divider()
                    .padding(.horizontal, 16)

                MenuButton(
                    icon: "power",
                    title: "Quit GhostSay",
                    action: { NSApplication.shared.terminate(nil) },
                )
            }
        }
        .environment(\.defaultMinListHeaderHeight, 0)
        .padding(.vertical, 8)
        .frame(minWidth: 260)
        .onHover { isHovering in
            dismissTimer?.invalidate()

            if !isHovering {
                // Start timer to dismiss menu after mouse leaves
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    dismissMenu()
                }
            }
        }
    }

    private var serverStatusTitle: String {
        serverManager.isRunning ? "Server Running" : "Server Stopped"
    }

    private var serverToggleText: String {
        serverManager.isRunning ? "Stop Server" : "Start Server"
    }

    private var statusColor: Color {
        if serverManager.lastError != nil {
            return .red
        }
        return serverManager.isRunning ? .green : .gray
    }

    private func toggleServer() {
        if serverManager.isRunning {
            serverManager.stop()
        } else {
            serverManager.start()
        }
    }

    private func testVoice() {
        Task {
            _ = await serverManager.executeSayCommand(text: "GhostSay is working!")
        }
    }

    private func copyEndpoint() {
        let endpoint = "http://\(serverManager.selectedIP):\(String(serverManager.port))/say?text=Hello"
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(endpoint, forType: .string)
    }

    private func dismissMenu() {
        // Find and close the MenuBarExtra window
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.className.contains("MenuBarExtra") || $0.title.isEmpty }) {
                window.orderOut(nil)
            }
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 16)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear),
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
