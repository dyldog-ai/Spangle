import SwiftUI

/// Lightweight SwiftUI preview matching each SpriteKit character treatment.
struct CharacterPortrait: View {
    let design: CharacterDesign

    var body: some View {
        ZStack {
            if isPrestige {
                Circle()
                    .fill(AngularGradient(colors: palette + [palette[0]], center: .center))
                    .blur(radius: 8)
                    .padding(4)
            }
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.storybookInk, lineWidth: 4)
                }
                .padding(10)
            HStack(spacing: 13) {
                eye
                eye
            }
            .offset(y: -9)
            Capsule()
                .fill(scarfColor)
                .frame(width: 66, height: 13)
                .overlay(Capsule().stroke(Color.storybookInk, lineWidth: 2))
                .offset(y: 29)
            Image(systemName: accessorySymbol)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(accessoryColor)
                .shadow(color: .storybookInk.opacity(0.45), radius: 0, y: 2)
                .offset(y: -47)
        }
        .frame(width: 120, height: 120)
        .accessibilityHidden(true)
    }

    private var eye: some View {
        Capsule()
            .fill(Color.storybookPaper)
            .frame(width: 20, height: 28)
            .overlay(Capsule().stroke(Color.storybookInk, lineWidth: 3))
            .overlay(Circle().fill(Color.storybookInk).frame(width: 8, height: 10).offset(x: 2))
    }

    private var palette: [Color] {
        switch design.style {
        case .sol: [.storybookGold, .storybookCream]
        case .coral: [Color(red: 0.98, green: 0.38, blue: 0.28), .orange]
        case .forest: [Color(red: 0.18, green: 0.58, blue: 0.3), Color(red: 0.48, green: 0.76, blue: 0.25)]
        case .midnight: [Color(red: 0.08, green: 0.1, blue: 0.23), Color(red: 0.24, green: 0.18, blue: 0.48)]
        case .fiesta: [.pink, .orange, .yellow]
        case .ocean: [Color(red: 0.06, green: 0.43, blue: 0.66), .cyan]
        case .clockwork: [Color(red: 0.54, green: 0.3, blue: 0.12), Color(red: 0.94, green: 0.67, blue: 0.2)]
        case .astronaut: [Color(red: 0.84, green: 0.9, blue: 0.96), Color(red: 0.36, green: 0.5, blue: 0.72)]
        case .knight: [Color(red: 0.98, green: 0.76, blue: 0.16), Color(red: 0.64, green: 0.37, blue: 0.08)]
        case .dragon: [Color(red: 0.07, green: 0.65, blue: 0.55), Color(red: 0.28, green: 0.16, blue: 0.54), .cyan]
        case .aurora: [.purple, .cyan, .mint, .pink]
        case .legend: [.red, .orange, .yellow, .green, .cyan, .purple]
        case .isaac: [Color(red: 0.94, green: 0.82, blue: 0.72), Color(red: 0.45, green: 0.7, blue: 0.9)]
        case .moonwalker: [.black, Color(red: 0.28, green: 0.27, blue: 0.31), .white]
        case .stardust: [.orange, .red, .blue]
        case .sleuth: [Color(red: 0.62, green: 0.46, blue: 0.28), Color(red: 0.85, green: 0.74, blue: 0.5)]
        case .plumber: [.red, Color(red: 0.08, green: 0.28, blue: 0.7)]
        case .speedster: [Color(red: 0.04, green: 0.28, blue: 0.78), .cyan, .red]
        }
    }

    private var scarfColor: Color {
        switch design.style {
        case .midnight: .black
        case .ocean, .astronaut: .white
        case .forest: .storybookCream
        case .dragon: .purple
        case .aurora, .legend, .moonwalker: .storybookInk
        case .isaac: .storybookBlue
        case .plumber: .blue
        case .speedster: .red
        default: .storybookRed
        }
    }

    private var accessorySymbol: String {
        switch design.style {
        case .sol: "sun.max.fill"
        case .coral: "backpack.fill"
        case .forest: "leaf.fill"
        case .midnight: "moon.stars.fill"
        case .fiesta: "sparkles"
        case .ocean: "sailboat.fill"
        case .clockwork: "gearshape.2.fill"
        case .astronaut: "helmet.fill"
        case .knight: "shield.lefthalf.filled"
        case .dragon: "flame.fill"
        case .aurora: "crown.fill"
        case .legend: "staroflife.fill"
        case .isaac: "drop.fill"
        case .moonwalker: "hat.widebrim.fill"
        case .stardust: "bolt.fill"
        case .sleuth: "magnifyingglass"
        case .plumber: "wrench.adjustable.fill"
        case .speedster: "hare.fill"
        }
    }

    private var accessoryColor: Color {
        design.style == .astronaut ? .storybookBlue : .white
    }

    private var isPrestige: Bool {
        switch design.style {
        case .dragon, .aurora, .legend, .stardust, .speedster: true
        default: false
        }
    }
}
