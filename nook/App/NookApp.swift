import SwiftUI

@main
struct NookApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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

            Divider()

            Button("Quit Nook") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}
