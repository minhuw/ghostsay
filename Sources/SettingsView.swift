import SwiftUI

struct SettingsView: View {
    @StateObject private var serverManager = ServerManager.shared
    @State private var portString: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GhostSay Settings")
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text("Server Port:")
                    .fontWeight(.medium)

                TextField("Port", text: $portString)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)
                    .onSubmit {
                        savePort()
                    }

                Text("Default: 5000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .frame(width: 300, height: 200)
        .onAppear {
            portString = String(serverManager.port)
        }
    }

    private func savePort() {
        if let port = Int(portString), port > 0, port <= 65535 {
            serverManager.port = port
        } else {
            portString = String(serverManager.port)
        }
    }
}
