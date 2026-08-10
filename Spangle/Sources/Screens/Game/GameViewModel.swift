import Foundation
#if DEVELOPER_INTEGRATIONS
import QueKit
#endif
import SpriteKit
import SwiftUI

/// Owns the SpriteKit scene and drives campaign, challenge, and review progression.
@MainActor
final class GameViewModel: ObservableObject {
    enum Phase: Equatable {
        case menu
        case generating(listName: String)
        case listError(message: String)
        case intro(eyebrow: String, theme: Theme)
        case playing
        case paused
        case quiz(QuizQuestion)
        case reviewCorrection(QuizQuestion)
        case gameOver(reason: String)
        case results(RunSummary, nextTheme: Theme?)
    }

    @Published private(set) var phase: Phase
    @Published private(set) var themes: [Theme]
    @Published private(set) var levelIndex = 0
    @Published private(set) var unlockedThrough: Int
    @Published private(set) var wordsLearned = 0
    @Published private(set) var challengeStars = 0
    @Published private(set) var distance = 0
    @Published private(set) var progress = 0.0
    @Published private(set) var score = 0
    @Published private(set) var combo = 1
    @Published private(set) var shieldActive = false
    @Published private(set) var hasCheckpoint = false
    @Published private(set) var quizCorrect = 0
    @Published private(set) var quizMistakes = 0
    @Published var toast: VocabWord?

    let challengeStarTotal = Level.challengeStarCount
    let scene: GameScene
    let settings: GameSettings
    let learning: LearningProgressStore
    let characters: CharacterStore

    private let unlockKey = "highestUnlockedLevel"
    private let defaults: UserDefaults
    #if DEVELOPER_INTEGRATIONS
    private let wordListStore: WordListStore
    private let generator: FoundationModelsWordListGenerator
    private var generationTask: Task<Void, Never>?
    #endif
    private let feedback: GameFeedback
    private var finalQuizQueue = QuizWordQueue()
    private var isFinalQuizActive = false
    private var mode: GameMode = .campaign
    private var activeTheme: Theme?
    private var startedAt = Date()
    private var usedCheckpoint = false
    private var checkpointProgress: CheckpointProgress?

    private struct CheckpointProgress {
        let wordsLearned: Int
        let challengeStars: Int
        let score: Int
        let combo: Int
        let quizCorrect: Int
        let quizMistakes: Int
    }

    private var theme: Theme {
        activeTheme ?? themes[levelIndex]
    }

    var currentThemeName: String {
        activeTheme?.name ?? (themes.indices.contains(levelIndex) ? themes[levelIndex].name : "")
    }

    var learningAccuracyText: String { "\(Int((learning.accuracy * 100).rounded()))%" }
    var dailyBestScore: Int { defaults.integer(forKey: dailyScoreKey()) }
    var marathonBestScore: Int { defaults.integer(forKey: "bestScore.marathon") }

    #if DEVELOPER_INTEGRATIONS
    init(
        wordListStore: WordListStore = ICloudWordListStore(),
        generator: FoundationModelsWordListGenerator = FoundationModelsWordListGenerator(),
        defaults: UserDefaults = .standard
    ) {
        self.wordListStore = wordListStore
        self.generator = generator
        self.defaults = defaults
        settings = GameSettings(defaults: defaults)
        learning = LearningProgressStore(defaults: defaults)
        characters = CharacterStore(defaults: defaults)
        feedback = GameFeedback(settings: settings)
        themes = Campaign.themes + QueListLibrary.allBundledLists.compactMap { $0.spangleTheme() }
        scene = GameScene(size: CGSize(width: 1024, height: 576))
        scene.scaleMode = .resizeFill
        unlockedThrough = defaults.integer(forKey: unlockKey)
        phase = .menu
        finishInitialization()
    }
    #else
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = GameSettings(defaults: defaults)
        learning = LearningProgressStore(defaults: defaults)
        characters = CharacterStore(defaults: defaults)
        feedback = GameFeedback(settings: settings)
        themes = Campaign.themes
        scene = GameScene(size: CGSize(width: 1024, height: 576))
        scene.scaleMode = .resizeFill
        unlockedThrough = defaults.integer(forKey: unlockKey)
        phase = .menu
        finishInitialization()
    }
    #endif

    private func finishInitialization() {
        scene.game = self
        scene.load(
            words: Campaign.themes[0].words,
            difficulty: .forLevel(0),
            skin: .forLevel(0),
            seed: StableSeed.make(Campaign.themes[0].id)
        )
        scene.setCharacterDesign(characters.selected)
    }

    // MARK: - QueKit levels

    func reloadQueKitLevels() {
        #if DEVELOPER_INTEGRATIONS
        let userLists = (try? wordListStore.userLists()) ?? []
        let queKitThemes = (QueListLibrary.allBundledLists + userLists)
            .compactMap { $0.spangleTheme() }
        themes = Campaign.themes + queKitThemes
        #endif
    }

    func isLocked(_ index: Int) -> Bool {
        index < Campaign.themes.count && index > unlockedThrough
    }

    func bestStarRating(for index: Int) -> Int {
        guard themes.indices.contains(index) else { return 0 }
        return defaults.integer(forKey: starRatingKey(for: themes[index]))
    }

    #if DEVELOPER_INTEGRATIONS
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
                loadLevel(
                    index,
                    theme: generatedTheme,
                    mode: .imported,
                    difficultyIndex: min(index, 8),
                    seed: freshSeed(for: generatedTheme.id),
                    eyebrow: "QueKit Challenge"
                )
            } catch {
                guard !Task.isCancelled else { return }
                phase = .listError(message: "Couldn’t generate “\(list.name)”. Please try again.")
            }
        }
    }
    #endif

    // MARK: - Game selection

    func selectLevel(_ index: Int) {
        guard themes.indices.contains(index), !isLocked(index) else { return }
        let selectedTheme = themes[index]
        #if DEVELOPER_INTEGRATIONS
        if let list = selectedTheme.sourceList, list.isGenerated {
            generateAndLoadLevel(at: index, list: list)
        } else {
            let selectedMode: GameMode = index < Campaign.themes.count ? .campaign : .imported
            loadLevel(
                index,
                theme: selectedTheme,
                mode: selectedMode,
                difficultyIndex: min(index, 11),
                seed: freshSeed(for: selectedTheme.id),
                eyebrow: index < Campaign.themes.count ? "Nivel \(index + 1)" : "QueKit Challenge"
            )
        }
        #else
        loadLevel(
            index,
            theme: selectedTheme,
            mode: .campaign,
            difficultyIndex: min(index, 11),
            seed: freshSeed(for: selectedTheme.id),
            eyebrow: "Nivel \(index + 1)"
        )
        #endif
    }

    func startDailyChallenge() {
        let seed = dailySeed()
        var random = SeededGenerator(seed: seed)
        let words = Campaign.themes.flatMap(\.words).shuffled(using: &random).prefix(24)
        let dailyTheme = Theme(
            id: "daily.\(seed)",
            name: "Reto Diario",
            english: "Today’s mixed challenge",
            emoji: "☀️",
            words: Array(words)
        )
        loadLevel(
            0,
            theme: dailyTheme,
            mode: .daily(seed: seed),
            difficultyIndex: 7,
            seed: seed,
            eyebrow: "Daily Challenge"
        )
    }

    func startMarathon() {
        let marathonTheme = Theme(
            id: "marathon",
            name: "El Maratón",
            english: "All 96 campaign words",
            emoji: "🏁",
            words: Campaign.themes.flatMap(\.words)
        )
        loadLevel(
            0,
            theme: marathonTheme,
            mode: .marathon,
            difficultyIndex: 9,
            seed: freshSeed(for: "spangle.marathon"),
            eyebrow: "Marathon"
        )
    }

    func startReview() {
        let reviewWords = learning.reviewWords(from: Campaign.themes.flatMap(\.words))
        let reviewTheme = Theme(
            id: "review",
            name: "Repaso",
            english: "Adaptive platforming practice",
            emoji: "🧠",
            words: reviewWords
        )
        loadLevel(
            0,
            theme: reviewTheme,
            mode: .review,
            difficultyIndex: 2,
            seed: freshSeed(for: "spangle.review"),
            eyebrow: "Adaptive Word Review"
        )
    }

    func goToMenu() {
        #if DEVELOPER_INTEGRATIONS
        generationTask?.cancel()
        generationTask = nil
        #endif
        scene.pauseRun()
        feedback.stopMusic()
        phase = .menu
        activeTheme = nil
        reloadQueKitLevels()
    }

    private func loadLevel(
        _ index: Int,
        theme: Theme,
        mode: GameMode,
        difficultyIndex: Int,
        seed: UInt64,
        eyebrow: String
    ) {
        guard !theme.words.isEmpty else {
            phase = .listError(message: "“\(theme.name)” has no words yet.")
            return
        }
        if themes.indices.contains(index), mode == .campaign || mode == .imported {
            themes[index] = theme
        }
        feedback.stopMusic()
        activeTheme = theme
        self.mode = mode
        levelIndex = index
        resetRunProgress()
        scene.load(
            words: theme.words,
            difficulty: .forLevel(difficultyIndex),
            skin: .forLevel(difficultyIndex),
            seed: seed
        )
        scene.setCharacterDesign(characters.selected)
        phase = .intro(eyebrow: eyebrow, theme: theme)
    }

    func startLevel() {
        startedAt = .now
        phase = .playing
        feedback.startMusic(style: levelIndex)
        scene.begin()
    }

    func pause() {
        guard phase == .playing else { return }
        scene.pauseRun()
        feedback.pauseMusic()
        phase = .paused
    }

    func resume() {
        guard phase == .paused else { return }
        phase = .playing
        feedback.resumeMusic()
        scene.resumeRun()
    }

    func pauseIfPlaying() {
        if phase == .playing { pause() }
    }

    func continueAfterResults() {
        guard case let .results(_, nextTheme) = phase else { return }
        if let nextTheme, mode == .campaign,
           let nextIndex = themes.firstIndex(where: { $0.id == nextTheme.id }) {
            selectLevel(nextIndex)
        } else {
            goToMenu()
        }
    }

    // MARK: - Called by the scene

    func jumped() { feedback.jump() }

    func collected(_ word: VocabWord) {
        wordsLearned += 1
        combo = min(8, combo + 1)
        score += 100 * combo
        learning.recordExposure(to: word)
        toast = word
        feedback.pickup()
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            if toast == word { toast = nil }
        }
    }

    func collectedChallengeStar() {
        challengeStars = min(challengeStarTotal, challengeStars + 1)
        score += 500
        feedback.star()
    }

    func defeatedEnemy() {
        combo = min(8, combo + 1)
        score += 300 * combo
        feedback.star()
    }

    func refreshCharacterDesign() {
        scene.setCharacterDesign(characters.selected)
        objectWillChange.send()
    }

    func shieldChanged(isActive: Bool) {
        shieldActive = isActive
        if isActive { feedback.pickup() } else { feedback.damage() }
    }

    func reachedCheckpoint() {
        score += 250
        hasCheckpoint = true
        checkpointProgress = CheckpointProgress(
            wordsLearned: wordsLearned,
            challengeStars: challengeStars,
            score: score,
            combo: combo,
            quizCorrect: quizCorrect,
            quizMistakes: quizMistakes
        )
        feedback.checkpoint()
    }

    func updateRun(distanceMeters: Int, progress: Double) {
        distance = distanceMeters
        self.progress = progress
    }

    func presentQuiz(for word: VocabWord) {
        isFinalQuizActive = false
        presentQuestion(for: word, heading: "Translation gate")
    }

    func died(reason: String) {
        combo = 1
        feedback.pauseMusic()
        feedback.damage()
        phase = .gameOver(reason: reason)
    }

    func finished() {
        feedback.pauseMusic()
        isFinalQuizActive = true
        finalQuizQueue = QuizWordQueue(words: theme.words)
        presentNextFinalQuiz()
    }

    // MARK: - Quizzes

    private func presentQuestion(for word: VocabWord, heading: String) {
        let direction = learning.preferredDirection(for: word)
        phase = .quiz(theme.question(for: word, direction: direction, heading: heading))
    }

    private func presentNextFinalQuiz() {
        guard let word = finalQuizQueue.takeRandom() else {
            completeRun()
            return
        }
        presentQuestion(
            for: word,
            heading: "Final quiz · \(finalQuizQueue.count + 1) left"
        )
    }

    func answer(_ answer: String) {
        guard case let .quiz(question) = phase else { return }
        let correct = answer == question.correctAnswer
        learning.recordAnswer(to: question.word, direction: question.direction, correct: correct)

        if correct {
            quizCorrect += 1
            combo = min(8, combo + 1)
            score += 200 * combo
            feedback.correct()
            if isFinalQuizActive {
                presentNextFinalQuiz()
            } else {
                phase = .playing
                scene.resumeFromGate()
            }
        } else {
            quizMistakes += 1
            combo = 1
            feedback.damage()
            if mode == .review {
                phase = .reviewCorrection(question)
            } else {
                phase = .gameOver(
                    reason: "\(question.prompt) means “\(question.correctAnswer)”"
                )
            }
        }
    }

    func continueReviewAfterCorrection() {
        guard case .reviewCorrection = phase else { return }
        if isFinalQuizActive {
            presentNextFinalQuiz()
        } else {
            phase = .playing
            scene.resumeFromGate()
        }
    }

    private func completeRun() {
        isFinalQuizActive = false
        progress = 1
        score += max(0, 1_000 - quizMistakes * 100)
        characters.deposit(stars: challengeStars)
        saveBestStarRating()
        saveBestScore()
        if mode.recordsCampaignProgress && levelIndex < Campaign.themes.count {
            unlock(levelIndex + 1)
        }
        let nextTheme: Theme?
        if mode == .campaign, levelIndex + 1 < Campaign.themes.count {
            nextTheme = themes[levelIndex + 1]
        } else {
            nextTheme = nil
        }
        let summary = RunSummary(
            title: theme.name,
            score: score,
            wordsCollected: wordsLearned,
            correctAnswers: quizCorrect,
            mistakes: quizMistakes,
            stars: challengeStars,
            duration: Date.now.timeIntervalSince(startedAt),
            usedCheckpoint: usedCheckpoint
        )
        feedback.stopMusic()
        feedback.complete()
        phase = .results(summary, nextTheme: nextTheme)
    }

    // MARK: - Retry and persistence

    func retryFromCheckpoint() {
        guard let checkpointProgress, scene.restartFromCheckpoint() else {
            retry()
            return
        }
        wordsLearned = checkpointProgress.wordsLearned
        challengeStars = checkpointProgress.challengeStars
        score = checkpointProgress.score
        combo = checkpointProgress.combo
        quizCorrect = checkpointProgress.quizCorrect
        quizMistakes = checkpointProgress.quizMistakes
        toast = nil
        usedCheckpoint = true
        feedback.startMusic(style: levelIndex)
        phase = .playing
    }

    func retry() {
        resetRunProgress()
        startedAt = .now
        phase = .playing
        feedback.startMusic(style: levelIndex)
        scene.restart()
        scene.begin()
    }

    func resetAllProgress() {
        defaults.removeObject(forKey: unlockKey)
        for key in defaults.dictionaryRepresentation().keys
            where key.hasPrefix("challengeStarRating.") || key.hasPrefix("bestScore.") {
            defaults.removeObject(forKey: key)
        }
        learning.reset()
        characters.reset()
        scene.setCharacterDesign(characters.selected)
        unlockedThrough = 0
        objectWillChange.send()
    }

    private func resetRunProgress() {
        wordsLearned = 0
        challengeStars = 0
        distance = 0
        progress = 0
        score = 0
        combo = 1
        shieldActive = false
        hasCheckpoint = false
        quizCorrect = 0
        quizMistakes = 0
        toast = nil
        finalQuizQueue.removeAll()
        checkpointProgress = nil
        isFinalQuizActive = false
        usedCheckpoint = false
    }

    private func unlock(_ index: Int) {
        let capped = min(index, Campaign.themes.count - 1)
        guard capped > unlockedThrough else { return }
        unlockedThrough = capped
        defaults.set(capped, forKey: unlockKey)
    }

    private func saveBestStarRating() {
        let key = starRatingKey(for: theme)
        guard challengeStars > defaults.integer(forKey: key) else { return }
        defaults.set(challengeStars, forKey: key)
    }

    private func saveBestScore() {
        let key: String?
        switch mode {
        case .daily:
            key = dailyScoreKey()
        case .marathon:
            key = "bestScore.marathon"
        case .campaign, .imported:
            key = "bestScore.\(theme.id)"
        case .review:
            key = nil
        }
        guard let key, score > defaults.integer(forKey: key) else { return }
        defaults.set(score, forKey: key)
    }

    private func starRatingKey(for theme: Theme) -> String {
        "challengeStarRating.\(theme.id)"
    }

    private func freshSeed(for identifier: String) -> UInt64 {
        StableSeed.make(identifier) ^ UInt64.random(in: 1...UInt64.max)
    }

    private func dailySeed(on date: Date = .now) -> UInt64 {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd"
        return StableSeed.make(formatter.string(from: date))
    }

    private func dailyScoreKey() -> String {
        "bestScore.daily.\(dailySeed())"
    }
}
