import SwiftUI

struct ShortcutGridView: View {
    let items: [ShortcutItem]
    let columns: Int
    let onItemTapped: (ShortcutItem) -> Void

    var body: some View {
        GlassEffectContainer(spacing: 4) {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 4),
                    count: columns
                ),
                spacing: 4
            ) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    ShortcutItemView(
                        item: item,
                        position: index + 1
                    ) {
                        onItemTapped(item)
                    }
                }
            }
        }
    }
}
