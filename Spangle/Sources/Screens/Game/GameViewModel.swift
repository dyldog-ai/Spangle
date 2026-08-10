import QueKit
import SpriteKit
import SwiftUI

/// Owns the SpriteKit scene and drives progression through built-in and QueKit levels.
@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable {
        case menu
        case generating(listName: String)
        case listError(message: String)
        case intro(level: Int, theme: Theme)
        case playing
        case quiz(word: VocabWord, options: [String], heading: String)
        case gameOver(reason: String)
        case levelComplete(nextTheme: Theme)
        case campaignComplete
    }

    @Published private(set) var phase: Phase
    @Published private(set) var themes: [Theme]
    @Published private(set) var levelIndex = 0
    /// Highest built-in campaign level index the player has unlocked.
    @Published private(set) var unlockedThrough: Int
    @Published private(set) var wordsLearned = 0
    @Published private(set) var distance = 0
    @Published var toast: VocabWord?

    let scene: GameScene

    private let unlockKey = "highestUnlockedLevel"
    private let wordListStore: WordListStore
    private let generator: FoundationModelsWordListGenerator
    private var generationTask: Task<Void, Never>?
    private var finalQuizQueue = QuizWordQueue()
    private var isFinalQuizActive = false

    private var theme: Theme { themes[levelIndex] }
    var currentThemeName: String { themes.indices.contains(levelIndex) ? theme.name : "" }

    init(
        wordListStore: WordListStore = ICloudWordListStore(),
        generator: FoundationModelsWordListGenerator = FoundationModelsWordListGenerator()
    ) {
        self.wordListStore = wordListStore
        self.generator = generator
        themes = Campaign.themes + QueListLibrary.allBundledLists.compactMap { $0.spangleTheme() }
        scene = GameScene(size: CGSize(width: 1024, height: 576))
        scene.scaleMode = .resizeFill
        unlockedThrough = UserDefaults.standard.integer(forKey: unlockKey)
        phase = .menu
        scene.game = self
        scene.load(
            words: Campaign.themes[0].words,
            difficulty: .forLevel(0),
            skin: .forLevel(0)
        )
    }

    // MARK: - QueKit levels

    /// Reloads iCloud lists so changes made in Que or another app appear in the menu.
    func reloadQueKitLevels() {
        let userLists = (try? wordListStore.userLists()) ?? []
        let queKitThemes = (QueListLibrary.allBundledLists + userLists)
            .compactMap { $0.spangleTheme() }
        themes = Campaign.themes + queKitThemes
    }

    func isLocked(_ index: Int) -> Bool {
        index < Campaign.themes.count && index > unlockedThrough
    }

    private func generateAndLoadLevel(at index: Int, list: WordList) {
        guard generator.isAvailable else {
            phase = .listError(message: "Apple Intelligence is unavailable, so “\(list.name)” can’t be generated on this device.")
            return
        }

        generationTask?.cancel()
        phase = .generating(listName: list.name)
        generationTask = Task { [weak self] in
            guard let self else { return }
            do {
                let prompt = list.prompt?.isEmpty == false ? list.prompt! : list.name
                let generated = try await generator.generate(
                    prompt: prompt,
                    front: list.front,
                    back: list.back,
                    count: 16
                )
                guard !Task.isCancelled, let generatedTheme = list.spangleTheme(words: generated) else {
                    return
                }
                loadLevel(index, theme: generatedTheme)
            } catch {
                guard !Task.isCancelled else { return }
                phase = .listError(message: "Couldn’t generate “\(list.name)”. Please try again.")
            }
        }
    }

    // MARK: - Progression

    /// Picks a built-in or QueKit level. QueKit levels are always unlocked.
    func selectLevel(_ index: Int) {
        guard themes.indices.contains(index), !isLocked(index) else { return }
        let selectedTheme = themes[index]
        if let list = selectedTheme.sourceList, list.isGenerated {
            generateAndLoadLevel(at: index, list: list)
        } else {
            loadLevel(index, theme: selectedTheme)
        }
    }

    func goToMenu() {
        generationTask?.cancel()
        generationTask = nil
        phase = .menu
        reloadQueKitLevels()
    }

    private func loadLevel(_ index: Int, theme: Theme) {
        guard !theme.words.isEmpty else {
            phase = .listError(message: "“\(theme.name)” has no words yet.")
            return
        }
        themes[index] = theme
        levelIndex = index
        wordsLearned = 0
        distance = 0
        toast = nil
        finalQuizQueue.removeAll()
        isFinalQuizActive = false
        scene.load(words: theme.words, difficulty: .forLevel(index), skin: .forLevel(index))
        phase = .intro(level: index + 1, theme: theme)
    }

    func startLevel() {
        phase = .playing
        scene.begin()
    }

    func nextLevel() {
        selectLevel(levelIndex + 1)
    }

    func restartCampaign() {
        selectLevel(0)
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
        isFinalQuizActive = false
        phase = .quiz(
            word: word,
            options: theme.quiz(for: word),
            heading: "What does this mean?"
        )
    }

    func died(reason: String) {
        phase = .gameOver(reason: reason)
    }

    func finished() {
        isFinalQuizActive = true
        finalQuizQueue = QuizWordQueue(words: theme.words)
        presentNextFinalQuiz()
    }

    private func presentNextFinalQuiz() {
        guard let word = finalQuizQueue.takeRandom() else {
            completeLevel()
            return
        }
        phase = .quiz(
            word: word,
            options: theme.quiz(for: word),
            heading: "Final quiz · \(finalQuizQueue.count + 1) left"
        )
    }

    private func completeLevel() {
        isFinalQuizActive = false
        if levelIndex < Campaign.themes.count {
            unlock(levelIndex + 1)
        }
        let next = levelIndex + 1
        phase = next < themes.count ? .levelComplete(nextTheme: themes[next]) : .campaignComplete
    }

    private func unlock(_ index: Int) {
        let capped = min(index, Campaign.themes.count - 1)
        guard capped > unlockedThrough else { return }
        unlockedThrough = capped
        UserDefaults.standard.set(capped, forKey: unlockKey)
    }

    // MARK: - Called by the UI

    func answer(_ english: String) {
        guard case let .quiz(word, _, _) = phase else { return }
        if english == word.english {
            if isFinalQuizActive {
                presentNextFinalQuiz()
            } else {
                phase = .playing
                scene.resumeFromGate()
            }
        } else {
            phase = .gameOver(reason: "«\(word.spanish)» means “\(word.english)”")
        }
    }

    func retry() {
        wordsLearned = 0
        distance = 0
        toast = nil
        finalQuizQueue.removeAll()
        isFinalQuizActive = false
        phase = .playing
        scene.restart()
        scene.begin()
    }
}
