import SwiftUI

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var accessibilityGranted = AXIsProcessTrusted()
    @State private var appleEventsGranted = false
    @State private var pollTask: Task<Void, Never>?

    private var allGranted: Bool {
        accessibilityGranted && appleEventsGranted
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Nook")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Nook needs a couple of permissions to send commands to your terminal.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 360)

            VStack(spacing: 16) {
                PermissionRow(
                    title: "Accessibility",
                    description: "Required to open new tabs and type commands in your terminal.",
                    granted: accessibilityGranted,
                    action: {
                        openSettings("Privacy_Accessibility")
                    }
                )

                PermissionRow(
                    title: "Automation",
                    description: "Required to communicate with terminal apps via Apple Events.",
                    granted: appleEventsGranted,
                    action: {
                        triggerAppleEventsPrompt()
                    }
                )
            }
            .padding(.vertical, 8)

            if allGranted {
                Button("Get Started") {
                    UserDefaults.standard.set(true, forKey: "onboardingCompleted")
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Text("Grant the permissions above, then this screen will update automatically.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(width: 480)
        .task {
            await pollPermissions()
        }
    }

    private func pollPermissions() async {
        while !Task.isCancelled {
            let ax = AXIsProcessTrusted()
            let ae = testAppleEvents()

            if ax != accessibilityGranted {
                accessibilityGranted = ax
            }
            if ae != appleEventsGranted {
                appleEventsGranted = ae
            }

            if ax && ae {
                // Bring the window to front so the user sees "Get Started"
                NSApp.activate(ignoringOtherApps: true)
                break
            }

            try? await Task.sleep(for: .seconds(1.5))
        }
    }

    private nonisolated func testAppleEvents() -> Bool {
        guard let script = NSAppleScript(source: """
        tell application "System Events"
            return name of first process whose frontmost is true
        end tell
        """) else { return false }

        var error: NSDictionary?
        script.executeAndReturnError(&error)
        return error == nil
    }

    private func openSettings(_ section: String) {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?\(section)")!
        )
    }

    private func triggerAppleEventsPrompt() {
        let script = NSAppleScript(source: """
        tell application "System Events"
            return name of first process whose frontmost is true
        end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: granted ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(granted ? .green : .secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            if !granted {
                Button("Enable") {
                    action()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(granted ? .green.opacity(0.08) : .secondary.opacity(0.06))
        )
    }
}
