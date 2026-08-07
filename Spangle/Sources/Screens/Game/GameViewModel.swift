import SpriteKit
import SwiftUI

/// Owns the SpriteKit scene and drives progression through the themed campaign.
@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable {
        case menu
        case intro(level: Int, theme: Theme)
        case playing
        case quiz(word: VocabWord, options: [String])
        case gameOver(reason: String)
        case levelComplete(nextTheme: Theme)
        case campaignComplete
    }

    @Published private(set) var phase: Phase
    @Published private(set) var levelIndex = 0
    /// Highest level index the player has unlocked (0 = only the first level).
    @Published private(set) var unlockedThrough: Int
    @Published private(set) var wordsLearned = 0
    @Published private(set) var distance = 0
    /// A brief translation banner shown when a coin is collected.
    @Published var toast: VocabWord?

    let scene: GameScene

    private let unlockKey = "highestUnlockedLevel"
    private var themes: [Theme] { Campaign.themes }
    private var theme: Theme { themes[levelIndex] }

    init() {
        scene = GameScene(size: CGSize(width: 1024, height: 576))
        scene.scaleMode = .resizeFill
        unlockedThrough = UserDefaults.standard.integer(forKey: unlockKey)
        let first = Campaign.themes[0]
        phase = .menu
        scene.game = self
        scene.load(words: first.words, difficulty: .forLevel(0), skin: .forLevel(0))
    }

    // MARK: - Progression

    /// Pick a level from the main menu. Ignores locked levels.
    func selectLevel(_ index: Int) {
        guard index <= unlockedThrough else { return }
        loadLevel(index)
    }

    func goToMenu() {
        phase = .menu
    }

    private func loadLevel(_ index: Int) {
        levelIndex = index
        wordsLearned = 0
        distance = 0
        toast = nil
        scene.load(words: theme.words, difficulty: .forLevel(index), skin: .forLevel(index))
        phase = .intro(level: index + 1, theme: theme)
    }

    /// Dismiss the intro and start playing the current level.
    func startLevel() {
        phase = .playing
        scene.begin()
    }

    func nextLevel() {
        loadLevel(levelIndex + 1)
    }

    func restartCampaign() {
        loadLevel(0)
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
        phase = .quiz(word: word, options: theme.quiz(for: word))
    }

    func died(reason: String) {
        phase = .gameOver(reason: reason)
    }

    func finished() {
        unlock(levelIndex + 1)
        let next = levelIndex + 1
        phase = next < themes.count ? .levelComplete(nextTheme: themes[next]) : .campaignComplete
    }

    /// Unlock up to `index`, persisting the highest reached.
    private func unlock(_ index: Int) {
        let capped = min(index, themes.count - 1)
        guard capped > unlockedThrough else { return }
        unlockedThrough = capped
        UserDefaults.standard.set(capped, forKey: unlockKey)
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

    /// Retry the current level after dying.
    func retry() {
        wordsLearned = 0
        distance = 0
        toast = nil
        phase = .playing
        scene.restart()
        scene.begin()
    }
}
