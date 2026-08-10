import SwiftUI

/// Main menu: title plus a scrollable grid of all levels to pick from.
struct MenuView: View {
    let themes: [Theme]
    let isLocked: (Int) -> Bool
    let onSelect: (Int) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14),
    ]

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

                ScrollView(.vertical) {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 14) {
                        ForEach(Array(themes.enumerated()), id: \.element.id) { index, theme in
                            let locked = isLocked(index)
                            Button { onSelect(index) } label: {
                                LevelTile(number: index + 1, theme: theme,
                                          skin: .forLevel(index), locked: locked)
                            }
                            .buttonStyle(.plain)
                            .disabled(locked)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// A single level card in the menu grid.
private struct LevelTile: View {
    let number: Int
    let theme: Theme
    let skin: Skin
    let locked: Bool

    private var gradient: LinearGradient {
        LinearGradient(colors: [Color(cgColor: skin.skyTop.cgColor),
                                Color(cgColor: skin.grass.cgColor)],
                       startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(locked ? "🔒" : theme.emoji).font(.system(size: 40))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            Text("Nivel \(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            Text(theme.name)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: true)
                .minimumScaleFactor(0.8)
            Text(locked ? "Locked" : theme.english)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 154)
        .padding(.horizontal, 8)
        .background(gradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .saturation(locked ? 0 : 1)
        .opacity(locked ? 0.55 : 1)
    }
}
