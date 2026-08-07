import SwiftUI

/// Main menu: title plus a scrollable grid of all levels to pick from.
struct MenuView: View {
    let themes: [Theme]
    let onSelect: (Int) -> Void

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.53, green: 0.81, blue: 0.98),
                                    Color(red: 0.29, green: 0.6, blue: 0.32)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("Spangle").font(.system(size: 44, weight: .heavy, design: .rounded))
                    Text("Learn Spanish · one jump at a time")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .foregroundStyle(.white)
                .padding(.top, 12)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(themes.enumerated()), id: \.element.id) { index, theme in
                            Button { onSelect(index) } label: {
                                LevelTile(number: index + 1, theme: theme)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}

/// A single level card in the menu grid.
private struct LevelTile: View {
    let number: Int
    let theme: Theme

    var body: some View {
        VStack(spacing: 6) {
            Text(theme.emoji).font(.system(size: 40))
            Text("Nivel \(number)")
                .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            Text(theme.name)
                .font(.headline).multilineTextAlignment(.center)
            Text(theme.english)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}
