import Foundation

/// A single vocabulary pair used for word-coins and translation gates.
struct VocabWord: Identifiable, Equatable, Hashable {
    let id: String
    let spanish: String
    let english: String

    init(spanish: String, english: String) {
        self.spanish = spanish
        self.english = english
        id = "\(Self.normalized(spanish))|\(Self.normalized(english))"
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
