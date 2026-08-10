import QYayKit
import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var model = GameViewModel()
    @State private var showsDeveloperNotes = false

    var body: some View {
        #if os(iOS)
        gameContent
            .qyayNotesOnShake(configuration: .init(appName: "Spangle"))
        #else
        gameContent
            .qyayNotesSheet(
                isPresented: $showsDeveloperNotes,
                configuration: .init(appName: "Spangle")
            )
        #endif
    }

    private var gameContent: some View {
        ZStack {
            SpriteView(scene: model.scene)
                .ignoresSafeArea()

            if model.phase != .menu {
                hud
                toast
            }
            overlay
        }
        .task { model.reloadQueKitLevels() }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 405)
        #endif
    }

    private var hud: some View {
        VStack {
            HStack {
                Label("\(model.wordsLearned)", systemImage: "text.book.closed.fill")
                Spacer()
                Text(model.currentThemeName)
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
        case .menu:
            MenuView(
                themes: model.themes,
                isLocked: model.isLocked,
                onSelect: model.selectLevel
            )
        case .playing:
            EmptyView()
        case let .generating(listName):
            MessageOverlay(
                title: "Creating level… ✨",
                message: "Generating fresh words for \(listName)",
                button: "Cancel",
                action: model.goToMenu
            )
        case let .listError(message):
            MessageOverlay(
                title: "List unavailable",
                message: message,
                button: "Menu",
                action: model.goToMenu
            )
        case let .intro(level, theme):
            LevelCardOverlay(
                emoji: theme.emoji,
                eyebrow: "Nivel \(level)",
                title: theme.name,
                subtitle: theme.english,
                button: "¡Vamos!",
                action: model.startLevel,
                secondary: ("Menu", model.goToMenu)
            )
        case let .quiz(word, options, heading):
            QuizOverlay(word: word, options: options, heading: heading, onPick: model.answer)
        case let .gameOver(reason):
            MessageOverlay(
                title: "¡Ay!",
                message: reason,
                button: "Try again",
                action: model.retry,
                secondary: ("Menu", model.goToMenu)
            )
        case let .levelComplete(nextTheme):
            LevelCardOverlay(
                emoji: "🎉",
                eyebrow: "¡Nivel completado!",
                title: "You learned \(model.wordsLearned) words",
                subtitle: "Next: \(nextTheme.emoji) \(nextTheme.name)",
                button: "Next level",
                action: model.nextLevel,
                secondary: ("Menu", model.goToMenu)
            )
        case .campaignComplete:
            MessageOverlay(
                title: "¡Campeón! 🏆",
                message: "You finished every level. ¡Felicidades!",
                button: "Menu",
                action: model.goToMenu
            )
        }
    }
}
