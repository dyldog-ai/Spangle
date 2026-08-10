import SwiftUI

/// Main menu with campaign, challenge modes, imported lists, and learning tools.
struct MenuView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let themes: [Theme]
    let isLocked: (Int) -> Bool
    let bestStarRating: (Int) -> Int
    let dailyBest: Int
    let marathonBest: Int
    let onSelect: (Int) -> Void
    let onDaily: () -> Void
    let onMarathon: () -> Void
    let onReview: () -> Void
    let starBalance: Int
    let selectedCharacter: CharacterDesign
    let onCharacters: () -> Void
    let onLevelCreator: () -> Void
    let onProgress: () -> Void
    let onSettings: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 14),
    ]

    var body: some View {
        ZStack {
            StorybookBackdrop()

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
        ZStack {
            HStack(spacing: 8) {
                Button(action: onProgress) {
                    if horizontalSizeClass == .compact {
                        Image(systemName: "chart.bar.fill")
                            .frame(width: 24)
                    } else {
                        Label("Progress", systemImage: "chart.bar.fill")
                    }
                }
                .accessibilityLabel("Progress")
                Button(action: onSettings) {
                    if horizontalSizeClass == .compact {
                        Image(systemName: "gearshape.fill")
                            .frame(width: 24)
                    } else {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                }
                .accessibilityLabel("Settings")
                #if DEVELOPER_FEATURES
                Button(action: onLevelCreator) {
                    if horizontalSizeClass == .compact {
                        Image(systemName: "hammer.fill")
                            .frame(width: 24)
                    } else {
                        Label("Creator", systemImage: "hammer.fill")
                    }
                }
                .accessibilityLabel("Level Creator")
                #endif
                Spacer()
            }
            .buttonStyle(StorybookSecondaryButtonStyle())

            HStack {
                Spacer()
                Button(action: onCharacters) {
                    HStack(spacing: 7) {
                        Label("\(starBalance)", systemImage: "star.fill")
                            .foregroundStyle(Color.storybookGold)
                        if horizontalSizeClass != .compact {
                            Text(selectedCharacter.name)
                                .lineLimit(1)
                        }
                        Image(systemName: "tshirt.fill")
                    }
                }
                .buttonStyle(StorybookSecondaryButtonStyle())
                .accessibilityLabel("Characters, \(starBalance) stars, \(selectedCharacter.name) equipped")
            }

            VStack(spacing: -3) {
                Text("SPANGLE")
                    .font(.system(size: 39, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(Color.storybookPaper)
                    .shadow(color: .storybookInk.opacity(0.75), radius: 0, y: 3)
                Text("APRENDE · SALTA · BRILLA")
                    .font(.caption2.weight(.black))
                    .tracking(2.1)
                    .foregroundStyle(Color.storybookCream)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Spangle. Learn Spanish, one jump at a time.")
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var challengeModes: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Play")
                .font(.title2.bold())
                .foregroundStyle(Color.storybookPaper)
                .shadow(color: .storybookInk.opacity(0.45), radius: 0, y: 2)
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
                    subtitle: "Run with your weakest words",
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
            .foregroundStyle(Color.storybookInk)
            .padding(13)
            .frame(maxWidth: .infinity, minHeight: 70)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.storybookPaper.opacity(0.94))
                    .shadow(color: .storybookInk.opacity(0.28), radius: 0, y: 4)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.storybookInk.opacity(0.42), lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
    }

    private func levelSection(title: String, items: [(offset: Int, element: Theme)]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(Color.storybookPaper)
                .shadow(color: .storybookInk.opacity(0.45), radius: 0, y: 2)
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
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(gradient)
                .shadow(color: .storybookInk.opacity(0.3), radius: 0, y: 5)
                .shadow(color: .black.opacity(0.16), radius: 8, y: 6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.storybookPaper.opacity(0.88), lineWidth: 4)
                .padding(2)
        }
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.storybookInk.opacity(0.48), lineWidth: 2))
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
