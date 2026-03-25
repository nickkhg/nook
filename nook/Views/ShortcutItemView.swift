import SwiftUI

struct ShortcutItemView: View {
    let item: ShortcutItem
    let onTap: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    // Soft glow behind icon on hover
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    .white.opacity(isHovering ? 0.12 : 0),
                                    .clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 32
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(nsImage: IconProvider.icon(for: item))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(.rect(cornerRadius: 12))
                        .shadow(
                            color: .black.opacity(0.4),
                            radius: isHovering ? 8 : 4,
                            y: isHovering ? 4 : 2
                        )
                }

                Text(item.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(
                        isHovering
                            ? .white
                            : .white.opacity(0.7)
                    )
            }
            .frame(width: 76, height: 88)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(isHovering ? 0.08 : 0))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                .white.opacity(isHovering ? 0.12 : 0),
                                lineWidth: 0.5
                            )
                    }
            )
            .scaleEffect(isPressed ? 0.92 : (isHovering ? 1.04 : 1.0))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(duration: 0.25, bounce: 0.2)) {
                isHovering = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.spring(duration: 0.15)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                        isPressed = false
                    }
                }
        )
    }
}
