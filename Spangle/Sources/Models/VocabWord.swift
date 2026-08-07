import Foundation

/// A single vocabulary pair used for word-coins and translation gates.
struct VocabWord: Identifiable, Equatable {
    let id = UUID()
    let spanish: String
    let english: String

    static func == (lhs: VocabWord, rhs: VocabWord) -> Bool {
        lhs.id == rhs.id
    }
}
