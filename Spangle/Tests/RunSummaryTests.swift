import Testing
@testable import Spangle

struct RunSummaryTests {
    @Test
    func accuracyUsesAllQuizAnswers() {
        let summary = RunSummary(
            title: "Test",
            score: 1_000,
            wordsCollected: 8,
            correctAnswers: 7,
            mistakes: 1,
            stars: 3,
            duration: 60,
            usedCheckpoint: false
        )
        #expect(summary.accuracy == 88)
    }

    @Test
    func emptyQuizHasZeroAccuracy() {
        let summary = RunSummary(
            title: "Test",
            score: 0,
            wordsCollected: 0,
            correctAnswers: 0,
            mistakes: 0,
            stars: 0,
            duration: 0,
            usedCheckpoint: false
        )
        #expect(summary.accuracy == 0)
    }
}
