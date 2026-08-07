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
        case .playing:
            EmptyView()
        case let .quiz(word, options):
            QuizOverlay(word: word, options: options) { model.answer($0) }
        case let .gameOver(reason):
            MessageOverlay(title: "¡Ay!", message: reason,
                           button: "Try again") { model.restart() }
        case .won:
            MessageOverlay(title: "¡Ganaste! 🎉",
                           message: "You learned \(model.wordsLearned) words.",
                           button: "Play again") { model.restart() }
        }
    }
}
