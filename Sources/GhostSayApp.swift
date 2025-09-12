import Cocoa
import SwiftUI

@main
struct GhostSayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var serverManager = ServerManager.shared

    var body: some Scene {
        MenuBarExtra("GhostSay", systemImage: menuBarIcon) {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Window("GhostSay Settings", id: "settings") {
            SettingsView()
                .onAppear {
                    configureSettingsWindow()
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    private var menuBarIcon: String {
        serverManager.isRunning ? "speaker.wave.2.fill" : "speaker.wave.2"
    }

    private func configureSettingsWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "GhostSay Settings" }) else { return }

            // Make window appear on current space even in fullscreen
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

            // Set window level to float above fullscreen apps
            window.level = .floating

            // Center the window but don't steal focus
            window.center()
            window.orderFront(nil) // Show without making key

            // Don't activate the app - this prevents pulling focus from fullscreen apps
        }
    }
}
