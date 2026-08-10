import Foundation
import QueKit

extension WordList {
    /// Converts Spanish ↔ English QueKit lists into Spangle levels.
    func spangleTheme(words generatedWords: [Word]? = nil) -> Theme? {
        let sourceWords = generatedWords ?? words
        let spanishIsFront = front.localeIdentifier.hasPrefix("es") && back.localeIdentifier.hasPrefix("en")
        let spanishIsBack = back.localeIdentifier.hasPrefix("es") && front.localeIdentifier.hasPrefix("en")
        guard spanishIsFront || spanishIsBack else { return nil }
        guard isGenerated || !sourceWords.isEmpty else { return nil }

        let vocabulary = sourceWords.map { word in
            if spanishIsFront {
                VocabWord(spanish: word.front, english: word.back)
            } else {
                VocabWord(spanish: word.back, english: word.front)
            }
        }
        let subtitle = isGenerated
            ? "AI-generated · QueKit"
            : "\(vocabulary.count) words · QueKit"

        return Theme(
            id: "quekit.\(id)",
            name: name,
            english: subtitle,
            emoji: isGenerated ? "✨" : "📚",
            words: vocabulary,
            sourceList: self
        )
    }
}
