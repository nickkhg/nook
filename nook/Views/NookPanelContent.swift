import SwiftUI

struct NookPanelContent: View {
    let configuration: NookConfiguration
    let onItemTapped: (ShortcutItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Small notch connector tab
            Capsule()
                .fill(.white.opacity(0.15))
                .frame(width: 32, height: 4)
                .padding(.top, 6)

            ShortcutGridView(
                items: configuration.items,
                columns: configuration.columns,
                onItemTapped: onItemTapped
            )
            .padding(.horizontal, 10)
            .padding(.vertical, 12)
        }
        .glassEffect(.clear, in: .rect(cornerRadius: 18))
    }
}
