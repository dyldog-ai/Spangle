#if DEVELOPER_INTEGRATIONS
import QYayKit
#endif
import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var model = GameViewModel()
    #if DEVELOPER_FEATURES
    @StateObject private var levelCreatorStore = LevelCreatorStore()
    #endif
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var appScenePhase
    @State private var showsDeveloperNotes = false
    @State private var showsSettings = false
    @State private var showsProgress = false
    @State private var showsCharacters = false
    @State private var jumpPressActive = false
    #if DEVELOPER_FEATURES
    @State private var showsLevelCreator = false
    @State private var returnsToLevelCreator = false
    @State private var editingCustomLevelID: UUID?
    #endif

    var body: some View {
        #if DEVELOPER_INTEGRATIONS
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
        #else
        gameContent
        #endif
    }

    private var gameContent: some View {
        ZStack {
            SpriteView(scene: model.scene)
                .ignoresSafeArea()
                .contrast(model.settings.highContrast ? 1.25 : 1)
                .accessibilityHidden(true)

            if model.phase == .playing {
                gameplayInput
            }

            if model.phase != .menu {
                hud
                toast
            }
            overlay
            if model.phase == .menu && !hasCompletedOnboarding {
                OnboardingOverlay { hasCompletedOnboarding = true }
                    .zIndex(20)
            }
        }
        .task { model.reloadQueKitLevels() }
        .onChange(of: appScenePhase) { _, newPhase in
            if newPhase != .active { model.pauseIfPlaying() }
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView(
                settings: model.settings,
                onReset: {
                    model.resetAllProgress()
                    hasCompletedOnboarding = false
                },
                onUnlockEverything: model.unlockEverything,
                onClearUnlocks: model.clearLevelUnlocks
            )
        }
        .sheet(isPresented: $showsProgress) {
            LearningProgressView(store: model.learning, onReview: model.startReview)
        }
        .sheet(isPresented: $showsCharacters, onDismiss: model.refreshCharacterDesign) {
            CharacterShopView(
                store: model.characters,
                onSelectionChanged: model.refreshCharacterDesign
            )
        }
        #if DEVELOPER_FEATURES
            #if os(iOS)
            .fullScreenCover(isPresented: $showsLevelCreator) {
                LevelCreatorLibraryView(
                    store: levelCreatorStore,
                    initialEditorLevelID: editingCustomLevelID,
                    onPlay: playFromLevelCreator
                )
            }
            #else
            .sheet(isPresented: $showsLevelCreator) {
                LevelCreatorLibraryView(
                    store: levelCreatorStore,
                    initialEditorLevelID: editingCustomLevelID,
                    onPlay: playFromLevelCreator
                )
            }
            #endif
        #endif
        .transaction { transaction in
            if model.settings.reducedMotion { transaction.animation = nil }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 405)
        #endif
    }

    private var gameplayInput: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !jumpPressActive else { return }
                        jumpPressActive = true
                        model.scene.jumpBegan()
                    }
                    .onEnded { _ in
                        jumpPressActive = false
                        model.scene.jumpEnded()
                    }
            )
            .onDisappear {
                jumpPressActive = false
                model.scene.jumpEnded()
            }
            .accessibilityHidden(true)
    }

    private var hud: some View {
        VStack {
            VStack(spacing: 7) {
                HStack(spacing: 14) {
                    Button(action: model.pause) {
                        Image(systemName: "pause.fill")
                            .font(.caption.weight(.black))
                            .foregroundStyle(Color.storybookInk)
                            .frame(width: 34, height: 34)
                            .background(Color.storybookCream, in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pause game")

                    Label("\(model.wordsLearned)", systemImage: "text.book.closed.fill")
                    Label("\(model.challengeStars)/\(model.challengeStarTotal)", systemImage: "star.fill")
                    if model.shieldActive {
                        Label("Shield", systemImage: "shield.fill")
                            .foregroundStyle(.cyan)
                    }
                    Spacer()
                    VStack(spacing: 0) {
                        Text(model.currentThemeName).font(.headline)
                        Text("\(model.score.formatted()) · ×\(model.combo)")
                            .font(.caption.bold().monospacedDigit())
                    }
                    Spacer()
                    Label("\(model.distance) m", systemImage: "figure.run")
                }
                ProgressView(value: model.progress)
                    .tint(Color.storybookGold)
                    .background(.white.opacity(0.2), in: Capsule())
                    .accessibilityLabel("Level progress")
                    .accessibilityValue("\(Int(model.progress * 100)) percent")
            }
            .font(.headline.monospacedDigit())
            .foregroundStyle(Color.storybookPaper)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Rectangle()
                    .fill(model.settings.highContrast ? Color.black.opacity(0.9) : Color.storybookInk.opacity(0.72))
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.storybookGold.opacity(0.72)).frame(height: 2)
            }
            Spacer()
        }
    }

    @ViewBuilder private var toast: some View {
        if let word = model.toast {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    Image(systemName: "book.pages.fill")
                        .foregroundStyle(Color.storybookRed)
                    Text(word.spanish).fontWeight(.black)
                    Image(systemName: "arrow.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.storybookInk.opacity(0.45))
                    Text(word.english).fontWeight(.bold)
                }
                    .font(.title3)
                    .foregroundStyle(Color.storybookInk)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 11)
                    .background {
                        Capsule()
                            .fill(Color.storybookPaper)
                            .shadow(color: .storybookInk.opacity(0.28), radius: 0, y: 4)
                    }
                    .overlay(Capsule().stroke(Color.storybookInk.opacity(0.45), lineWidth: 2))
                    .padding(.bottom, 28)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .animation(model.settings.reducedMotion ? nil : .spring, value: model.toast)
            .accessibilityElement(children: .combine)
            .allowsHitTesting(false)
        }
    }

    private var customLevelMenuItems: [CustomLevelMenuItem] {
        #if DEVELOPER_FEATURES
        levelCreatorStore.levels.map {
            CustomLevelMenuItem(id: $0.id, title: $0.title, emoji: $0.emoji, wordCount: $0.words.count)
        }
        #else
        []
        #endif
    }

    private func playCustomLevel(id: UUID) {
        #if DEVELOPER_FEATURES
        guard let level = levelCreatorStore.levels.first(where: { $0.id == id }) else { return }
        returnsToLevelCreator = false
        editingCustomLevelID = nil
        model.playCustomLevel(level)
        #endif
    }

    #if DEVELOPER_FEATURES
    private func playFromLevelCreator(_ level: CustomLevelDefinition) {
        returnsToLevelCreator = true
        editingCustomLevelID = level.id
        model.playCustomLevel(level)
    }
    #endif

    private func leaveLevel() {
        model.goToMenu()
        #if DEVELOPER_FEATURES
        guard returnsToLevelCreator else { return }
        returnsToLevelCreator = false
        Task { @MainActor in showsLevelCreator = true }
        #endif
    }

    private func continueAfterResults() {
        #if DEVELOPER_FEATURES
        let shouldReturnToCreator = returnsToLevelCreator
        #else
        let shouldReturnToCreator = false
        #endif
        model.continueAfterResults()
        #if DEVELOPER_FEATURES
        if shouldReturnToCreator {
            returnsToLevelCreator = false
            Task { @MainActor in showsLevelCreator = true }
        }
        #endif
    }

    private func openLevelCreator() {
        #if DEVELOPER_FEATURES
        editingCustomLevelID = nil
        showsLevelCreator = true
        #endif
    }

    @ViewBuilder private var overlay: some View {
        switch model.phase {
        case .menu:
            MenuView(
                themes: model.themes,
                isLocked: model.isLocked,
                bestStarRating: model.bestStarRating,
                dailyBest: model.dailyBestScore,
                marathonBest: model.marathonBestScore,
                onSelect: model.selectLevel,
                onDaily: model.startDailyChallenge,
                onMarathon: model.startMarathon,
                onReview: model.startReview,
                customLevels: customLevelMenuItems,
                onCustomLevel: playCustomLevel,
                starBalance: model.characters.starBalance,
                selectedCharacter: model.characters.selected,
                onCharacters: { showsCharacters = true },
                onLevelCreator: openLevelCreator,
                onProgress: { showsProgress = true },
                onSettings: { showsSettings = true }
            )
        case .playing:
            EmptyView()
        case .paused:
            PauseOverlay(
                onResume: model.resume,
                onSettings: { showsSettings = true },
                onMenu: leaveLevel
            )
        case let .generating(listName):
            MessageOverlay(
                title: "Creating level… ✨",
                message: "Generating fresh words for \(listName)",
                button: "Cancel",
                action: leaveLevel
            )
        case let .listError(message):
            MessageOverlay(
                title: "List unavailable",
                message: message,
                button: "Menu",
                action: leaveLevel
            )
        case let .intro(eyebrow, theme):
            LevelCardOverlay(
                emoji: theme.emoji,
                eyebrow: eyebrow,
                title: theme.name,
                subtitle: "\(theme.english) · Find all \(model.challengeStarTotal) stars",
                button: "¡Vamos!",
                action: model.startLevel,
                secondary: ("Menu", leaveLevel)
            )
        case let .quiz(question):
            QuizOverlay(question: question, onPick: model.answer)
        case let .reviewCorrection(question):
            MessageOverlay(
                title: "Not quite",
                message: "\(question.prompt) means “\(question.correctAnswer)”.",
                button: "Continue review",
                action: model.continueReviewAfterCorrection
            )
        case let .gameOver(reason):
            GameOverOverlay(
                reason: reason,
                hasCheckpoint: model.hasCheckpoint,
                retryCheckpoint: model.retryFromCheckpoint,
                retryStart: model.retry,
                onMenu: leaveLevel
            )
        case let .results(summary, nextTheme):
            ResultsOverlay(
                summary: summary,
                nextTheme: nextTheme,
                onContinue: continueAfterResults,
                onMenu: leaveLevel
            )
        }
    }
}
