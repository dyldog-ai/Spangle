import QYayKit
import SpriteKit
import SwiftUI

struct GameView: View {
    @StateObject private var model = GameViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var appScenePhase
    @State private var showsDeveloperNotes = false
    @State private var showsSettings = false
    @State private var showsProgress = false

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
                .contrast(model.settings.highContrast ? 1.25 : 1)
                .accessibilityHidden(true)

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
            SettingsView(settings: model.settings) {
                model.resetAllProgress()
                hasCompletedOnboarding = false
            }
        }
        .sheet(isPresented: $showsProgress) {
            LearningProgressView(store: model.learning, onReview: model.startReview)
        }
        .transaction { transaction in
            if model.settings.reducedMotion { transaction.animation = nil }
        }
        #if os(macOS)
        .frame(minWidth: 720, minHeight: 405)
        #endif
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
        }
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
                onProgress: { showsProgress = true },
                onSettings: { showsSettings = true }
            )
        case .playing:
            EmptyView()
        case .paused:
            PauseOverlay(
                onResume: model.resume,
                onSettings: { showsSettings = true },
                onMenu: model.goToMenu
            )
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
        case let .intro(eyebrow, theme):
            LevelCardOverlay(
                emoji: theme.emoji,
                eyebrow: eyebrow,
                title: theme.name,
                subtitle: "\(theme.english) · Find all \(model.challengeStarTotal) stars",
                button: "¡Vamos!",
                action: model.startLevel,
                secondary: ("Menu", model.goToMenu)
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
                onMenu: model.goToMenu
            )
        case let .results(summary, nextTheme):
            ResultsOverlay(
                summary: summary,
                nextTheme: nextTheme,
                onContinue: model.continueAfterResults,
                onMenu: model.goToMenu
            )
        case let .reviewComplete(correct, total):
            MessageOverlay(
                title: "Review complete 🧠",
                message: "\(correct) of \(total) correct. Your next review will adapt to these answers.",
                button: "Menu",
                action: model.goToMenu,
                secondary: ("Review again", model.startReview)
            )
        }
    }
}
