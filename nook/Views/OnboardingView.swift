import SwiftUI

struct OnboardingView: View {
    @State private var accessibilityGranted = false
    @State private var appleEventsGranted = false
    @State private var checkTimer: Timer?

    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Nook")
                .font(.system(size: 28, weight: .bold, design: .rounded))

            Text("Nook needs a couple of permissions to send commands to your terminal.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            VStack(spacing: 16) {
                PermissionRow(
                    title: "Accessibility",
                    description: "Required to open new tabs and type commands in your terminal.",
                    granted: accessibilityGranted,
                    action: {
                        openAccessibilitySettings()
                    }
                )

                PermissionRow(
                    title: "Automation",
                    description: "Required to communicate with terminal apps via Apple Events.",
                    granted: appleEventsGranted,
                    action: {
                        // Trigger an Apple Events prompt by attempting a harmless script
                        triggerAppleEventsPrompt()
                    }
                )
            }
            .padding(.vertical, 8)

            if accessibilityGranted && appleEventsGranted {
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
        .onAppear { startChecking() }
        .onDisappear { checkTimer?.invalidate() }
    }

    private func startChecking() {
        // Check immediately
        checkPermissions()

        // Then poll every second
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            MainActor.assumeIsolated {
                checkPermissions()
            }
        }
    }

    private nonisolated func checkPermissions() {
        // Check Accessibility
        let axGranted = AXIsProcessTrusted()

        // Check Apple Events by attempting a harmless script
        let aeGranted = testAppleEvents()

        MainActor.assumeIsolated {
            accessibilityGranted = axGranted
            appleEventsGranted = aeGranted

            if axGranted && aeGranted {
                checkTimer?.invalidate()
                checkTimer = nil
            }
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

    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(
            URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        )
    }

    private func triggerAppleEventsPrompt() {
        // This will trigger the "allow nook to control System Events?" dialog
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
            }

            Spacer()

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
