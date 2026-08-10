import Foundation
#if DEVELOPER_INTEGRATIONS
import QueKit
#endif

/// A themed level and the vocabulary that appears in it.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let english: String
    let emoji: String
    let words: [VocabWord]
    #if DEVELOPER_INTEGRATIONS
    /// Present when this developer build imported the level from QueKit.
    let sourceList: WordList?
    #endif

    #if DEVELOPER_INTEGRATIONS
    init(
        id: String? = nil,
        name: String,
        english: String,
        emoji: String,
        words: [VocabWord],
        sourceList: WordList? = nil
    ) {
        self.id = id ?? "theme.\(name)"
        self.name = name
        self.english = english
        self.emoji = emoji
        self.words = words
        self.sourceList = sourceList
    }

    var isQueKitLevel: Bool { sourceList != nil }
    #else
    init(
        id: String? = nil,
        name: String,
        english: String,
        emoji: String,
        words: [VocabWord]
    ) {
        self.id = id ?? "theme.\(name)"
        self.name = name
        self.english = english
        self.emoji = emoji
        self.words = words
    }

    var isQueKitLevel: Bool { false }
    #endif

    static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }

    /// Builds a bidirectional multiple-choice question with unique distractors.
    func question(
        for word: VocabWord,
        direction: QuizQuestion.Direction,
        heading: String
    ) -> QuizQuestion {
        let answer: (VocabWord) -> String = direction == .spanishToEnglish
            ? { $0.english }
            : { $0.spanish }
        let correct = answer(word)
        let distractors = words
            .filter { $0.id != word.id }
            .map(answer)
            .filter { $0 != correct }
            .uniqued()
            .shuffled()
            .prefix(3)
        return QuizQuestion(
            word: word,
            direction: direction,
            options: ([correct] + distractors).shuffled(),
            heading: heading
        )
    }
}
