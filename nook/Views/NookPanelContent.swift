import SwiftUI

struct NookPanelContent: View {
    let configuration: NookConfiguration
    let onItemTapped: (ShortcutItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Notch connector -- a subtle tapered bridge from the notch
            NotchConnector()
                .frame(width: 36, height: 6)
                .padding(.top, 1)

            ShortcutGridView(
                items: configuration.items,
                columns: configuration.columns,
                onItemTapped: onItemTapped
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .background {
            PanelBackground()
        }
    }
}

// MARK: - Panel Background

struct PanelBackground: View {
    var body: some View {
        ZStack {
            // Base dark material
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            // Inner darkening layer for depth
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            .black.opacity(0.5),
                            .black.opacity(0.35),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Subtle top highlight edge (catches "light" from above)
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.2),
                            .white.opacity(0.05),
                            .clear,
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - Notch Connector

struct NotchConnector: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            // Tapered trapezoid that narrows toward the top
            let topInset: Double = 6
            p.move(to: CGPoint(x: topInset, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX - topInset, y: 0))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: 0, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
