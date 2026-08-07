import Foundation

/// A themed level: a Spanish title, an emoji and the vocabulary that appears
/// as word-coins and quiz distractors within it.
struct Theme: Identifiable, Equatable {
    let id = UUID()
    let name: String     // Spanish title, e.g. "Los Colores"
    let english: String  // English subtitle, e.g. "Colours"
    let emoji: String
    let words: [VocabWord]

    static func == (lhs: Theme, rhs: Theme) -> Bool { lhs.id == rhs.id }

    /// A multiple-choice quiz for `word` using same-theme distractors, which
    /// makes higher levels harder because the wrong options are more related.
    func quiz(for word: VocabWord) -> [String] {
        let wrong = words
            .filter { $0.id != word.id }
            .shuffled()
            .prefix(2)
            .map(\.english)
        return ([word.english] + wrong).shuffled()
    }
}
