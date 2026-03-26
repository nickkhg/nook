import SwiftUI

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboardingCompleted")

    var body: some Scene {
        MenuBarExtra("Nook", systemImage: "rectangle.topthird.inset.filled") {
            Button("Edit Configuration...") {
                let path = ConfigurationManager.shared.configFilePath
                NSWorkspace.shared.open(URL(fileURLWithPath: path))
            }
            .keyboardShortcut(",", modifiers: .command)

            Divider()

            Button("Reload Configuration") {
                ConfigurationManager.shared.reload()
            }
            .keyboardShortcut("r", modifiers: .command)

            Button("Setup Permissions...") {
                showOnboarding = true
            }

            Divider()

            Button("Quit Nook") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }

        Window("Nook Setup", id: "onboarding") {
            OnboardingView {
                showOnboarding = false
            }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
