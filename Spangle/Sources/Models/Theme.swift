import Foundation
import QueKit

/// A themed level and the vocabulary that appears in it.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let english: String
    let emoji: String
    let words: [VocabWord]
    /// Present when this level came from QueKit rather than the built-in campaign.
    let sourceList: WordList?

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

    static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }

    /// A multiple-choice quiz using distractors from the same list.
    func quiz(for word: VocabWord) -> [String] {
        let wrong = words
            .filter { $0.id != word.id }
            .shuffled()
            .prefix(2)
            .map(\.english)
        return ([word.english] + wrong).shuffled()
    }
}
