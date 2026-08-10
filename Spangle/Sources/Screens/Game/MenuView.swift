import SwiftUI

/// Main menu with campaign, challenge modes, imported lists, and learning tools.
struct MenuView: View {
    let themes: [Theme]
    let isLocked: (Int) -> Bool
    let bestStarRating: (Int) -> Int
    let dailyBest: Int
    let marathonBest: Int
    let onSelect: (Int) -> Void
    let onDaily: () -> Void
    let onMarathon: () -> Void
    let onReview: () -> Void
    let onProgress: () -> Void
    let onSettings: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.53, green: 0.81, blue: 0.98),
                         Color(red: 0.29, green: 0.6, blue: 0.32)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                header
                ScrollView(.vertical) {
                    VStack(alignment: .leading, spacing: 20) {
                        challengeModes
                        levelSection(
                            title: "Campaign",
                            items: Array(themes.prefix(Campaign.themes.count).enumerated())
                        )
                        let imported = themes.enumerated().filter { $0.offset >= Campaign.themes.count }
                        if !imported.isEmpty {
                            levelSection(title: "QueKit Lists", items: imported)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Button(action: onProgress) {
                    Label("Progress", systemImage: "chart.bar.fill")
                }
                Button(action: onSettings) {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .buttonStyle(.bordered)
            .tint(.white)

            Spacer()
            VStack(spacing: 0) {
                Text("Spangle")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                Text("Learn Spanish · one jump at a time")
                    .font(.subheadline)
            }
            .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 190, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var challengeModes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play")
                .font(.title2.bold())
                .foregroundStyle(.white)
            HStack(spacing: 12) {
                challengeButton(
                    title: "Daily Challenge",
                    subtitle: dailyBest == 0 ? "A new mixed run today" : "Best: \(dailyBest.formatted())",
                    icon: "sun.max.fill",
                    action: onDaily
                )
                challengeButton(
                    title: "Marathon",
                    subtitle: marathonBest == 0 ? "All 96 campaign words" : "Best: \(marathonBest.formatted())",
                    icon: "flag.checkered",
                    action: onMarathon
                )
                challengeButton(
                    title: "Word Review",
                    subtitle: "Practise your weakest words",
                    icon: "brain.head.profile",
                    action: onReview
                )
            }
        }
    }

    private func challengeButton(
        title: String,
        subtitle: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).opacity(0.8).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 68)
            .background(.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.white.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    private func levelSection(title: String, items: [(offset: Int, element: Theme)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.white)
            LazyVGrid(columns: columns, alignment: .center, spacing: 14) {
                ForEach(items, id: \.element.id) { index, theme in
                    let locked = isLocked(index)
                    Button { onSelect(index) } label: {
                        LevelTile(
                            number: index + 1,
                            theme: theme,
                            skin: .forLevel(index),
                            locked: locked,
                            starRating: bestStarRating(index)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(locked)
                }
            }
        }
    }
}

private struct LevelTile: View {
    let number: Int
    let theme: Theme
    let skin: Skin
    let locked: Bool
    let starRating: Int

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(cgColor: skin.skyTop.cgColor), Color(cgColor: skin.grass.cgColor)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(locked ? "🔒" : theme.emoji).font(.system(size: 40))
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            Text(theme.isQueKitLevel ? "QueKit" : "Nivel \(number)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.9))
            Text(theme.name)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(locked ? "Locked" : theme.english)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(2)
                .multilineTextAlignment(.center)
            if !locked {
                Text(starRatingText)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(starRating > 0 ? .yellow : .white.opacity(0.45))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(gradient, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(.white.opacity(0.35)))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        .saturation(locked ? 0 : 1)
        .opacity(locked ? 0.55 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var starRatingText: String {
        String(repeating: "★", count: starRating)
            + String(repeating: "☆", count: max(0, Level.challengeStarCount - starRating))
    }

    private var accessibilityLabel: String {
        locked
            ? "\(theme.name), locked"
            : "\(theme.name), best rating \(starRating) of 3 stars"
    }
}
