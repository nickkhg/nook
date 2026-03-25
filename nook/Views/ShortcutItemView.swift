import SwiftUI

struct ShortcutItemView: View {
    let item: ShortcutItem
    let onTap: () -> Void
    var taskManager: TaskManager = .shared

    @State private var isHovering = false

    private var isTask: Bool {
        if case .shellScript(_, _, let runAsTask) = item.type {
            return runAsTask == true
        }
        return false
    }

    private var isRunning: Bool {
        taskManager.isRunning(item.id)
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Image(nsImage: IconProvider.icon(for: item))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .clipShape(.rect(cornerRadius: 10))

                    // Running indicator: pulsing ring around the icon
                    if isRunning {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.green, lineWidth: 2)
                            .frame(width: 48, height: 48)
                            .modifier(PulseAnimation())
                    }
                }

                Text(item.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isRunning ? .green : .primary)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }

    private var backgroundColor: Color {
        if isRunning {
            .green.opacity(isHovering ? 0.2 : 0.1)
        } else {
            .white.opacity(isHovering ? 0.12 : 0)
        }
    }
}

/// Gentle pulse animation for the running indicator.
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(
                .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}
