import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var model = GameViewModel()

    var body: some View {
        ZStack {
            SpriteView(scene: model.scene)
                .ignoresSafeArea()

            hud
            toast
            overlay
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 405)
        #endif
    }

    private var hud: some View {
        VStack {
            HStack {
                Label("\(model.wordsLearned)", systemImage: "text.book.closed.fill")
                Spacer()
                Text(currentThemeName)
                    .font(.headline)
                Spacer()
                Label("\(model.distance) m", systemImage: "figure.run")
            }
            .font(.headline.monospacedDigit())
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            Spacer()
        }
    }

    private var currentThemeName: String {
        let themes = Campaign.themes
        return model.levelIndex < themes.count ? themes[model.levelIndex].name : ""
    }

    @ViewBuilder private var toast: some View {
        if let word = model.toast {
            VStack {
                Spacer()
                Text("\(word.spanish)  =  \(word.english)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(.black.opacity(0.55), in: Capsule())
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(.spring, value: model.toast)
        }
    }

    @ViewBuilder private var overlay: some View {
        switch model.phase {
        case .playing:
            EmptyView()
        case let .intro(level, theme):
            LevelCardOverlay(emoji: theme.emoji, eyebrow: "Nivel \(level)",
                             title: theme.name, subtitle: theme.english,
                             button: "¡Vamos!") { model.startLevel() }
        case let .quiz(word, options):
            QuizOverlay(word: word, options: options) { model.answer($0) }
        case let .gameOver(reason):
            MessageOverlay(title: "¡Ay!", message: reason,
                           button: "Try again") { model.retry() }
        case let .levelComplete(nextTheme):
            LevelCardOverlay(emoji: "🎉", eyebrow: "¡Nivel completado!",
                             title: "You learned \(model.wordsLearned) words",
                             subtitle: "Next: \(nextTheme.emoji) \(nextTheme.name)",
                             button: "Next level") { model.nextLevel() }
        case .campaignComplete:
            MessageOverlay(title: "¡Campeón! 🏆",
                           message: "You finished every level. ¡Felicidades!",
                           button: "Play again") { model.restartCampaign() }
        }
    }
}
