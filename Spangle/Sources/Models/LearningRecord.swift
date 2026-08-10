import Foundation

struct LearningRecord: Codable, Equatable {
    var spanish: String
    var english: String
    var exposures = 0
    var correctAnswers = 0
    var incorrectAnswers = 0
    var currentStreak = 0
    var spanishToEnglishAttempts = 0
    var englishToSpanishAttempts = 0
    var lastPractised: Date?

    var attempts: Int { correctAnswers + incorrectAnswers }

    var masteryLevel: Int {
        guard attempts > 0 else { return 0 }
        let accuracy = Double(correctAnswers) / Double(attempts)
        let evidence = min(1, Double(attempts) / 6)
        return min(5, max(0, Int((accuracy * evidence * 5).rounded(.down))))
    }

    func isDue(on date: Date = .now) -> Bool {
        guard let lastPractised else { return exposures > 0 }
        let reviewInterval = TimeInterval(max(1, masteryLevel * 2)) * 86_400
        return date.timeIntervalSince(lastPractised) >= reviewInterval
    }
}
