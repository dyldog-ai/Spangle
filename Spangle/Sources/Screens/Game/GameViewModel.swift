import SpriteKit
import SwiftUI

/// Owns the SpriteKit scene and publishes game state to SwiftUI overlays.
@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable {
        case playing
        case quiz(word: VocabWord, options: [String])
        case gameOver(reason: String)
        case won
    }

    @Published private(set) var phase: Phase = .playing
    @Published private(set) var wordsLearned = 0
    @Published private(set) var distance = 0
    /// A brief translation banner shown when a coin is collected.
    @Published var toast: VocabWord?

    let scene: GameScene

    init() {
        scene = GameScene(size: CGSize(width: 1024, height: 576))
        scene.scaleMode = .resizeFill
        scene.game = self
    }

    // MARK: - Called by the scene

    func collected(_ word: VocabWord) {
        wordsLearned += 1
        toast = word
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if toast == word { toast = nil }
        }
    }

    func updateDistance(_ meters: Int) {
        distance = meters
    }

    func presentQuiz(for word: VocabWord) {
        phase = .quiz(word: word, options: Vocabulary.quiz(for: word))
    }

    func died(reason: String) {
        phase = .gameOver(reason: reason)
    }

    func finished() {
        phase = .won
    }

    // MARK: - Called by the UI

    func answer(_ english: String) {
        guard case let .quiz(word, _) = phase else { return }
        if english == word.english {
            phase = .playing
            scene.resumeFromGate()
        } else {
            phase = .gameOver(reason: "«\(word.spanish)» means “\(word.english)”")
        }
    }

    func restart() {
        wordsLearned = 0
        distance = 0
        toast = nil
        phase = .playing
        scene.restart()
    }
}
