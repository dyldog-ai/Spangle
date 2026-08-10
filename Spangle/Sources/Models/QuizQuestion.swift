import Foundation

struct QuizQuestion: Equatable {
    enum Direction: String, Codable, Equatable {
        case spanishToEnglish
        case englishToSpanish
    }

    let word: VocabWord
    let direction: Direction
    let options: [String]
    let heading: String

    var prompt: String {
        direction == .spanishToEnglish ? word.spanish : word.english
    }

    var correctAnswer: String {
        direction == .spanishToEnglish ? word.english : word.spanish
    }
}
