import Foundation

struct RunSummary: Equatable {
    let title: String
    let score: Int
    let wordsCollected: Int
    let correctAnswers: Int
    let mistakes: Int
    let stars: Int
    let duration: TimeInterval
    let usedCheckpoint: Bool

    var accuracy: Int {
        let total = correctAnswers + mistakes
        return total == 0 ? 0 : Int((Double(correctAnswers) / Double(total) * 100).rounded())
    }
}
