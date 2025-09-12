import SwiftUI

struct MenuBarView: View {
    @StateObject private var serverManager = ServerManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(serverStatus)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            Button(serverToggleText) {
                toggleServer()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Button("Settings...") {
                openSettings()
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider()

            Button("Quit GhostSay") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
        }
        .frame(minWidth: 200)
    }

    private var serverStatus: String {
        if serverManager.isRunning {
            return "Server Running on Port \(serverManager.port)"
        } else {
            return "Server Stopped"
        }
    }

    private var serverToggleText: String {
        serverManager.isRunning ? "Stop Server" : "Start Server"
    }

    private func toggleServer() {
        if serverManager.isRunning {
            serverManager.stop()
        } else {
            serverManager.start()
        }
    }

    private func openSettings() {
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}
