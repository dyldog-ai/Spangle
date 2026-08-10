import Foundation
import Testing
@testable import Spangle

struct GameFeedbackTests {
    @MainActor @Test
    func proceduralToneUsesTheNegotiatedAudioRouteFormat() throws {
        let suite = "GameFeedbackTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = GameSettings(defaults: defaults)
        settings.soundEnabled = true
        let feedback = GameFeedback(settings: settings)

        // Scheduling is synchronous and raises an Objective-C exception when
        // the buffer channel count differs from the player's output format.
        feedback.jump()
        feedback.startMusic(style: 3)
        feedback.pauseMusic()
        feedback.resumeMusic()
        feedback.stopMusic()
    }
}
