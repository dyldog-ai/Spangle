import Foundation

/// Static beginner Spanish vocabulary. Kept small and concrete so the
/// quiz distractors are unambiguous.
enum Vocabulary {
    static let all: [VocabWord] = [
        .init(spanish: "gato", english: "cat"),
        .init(spanish: "perro", english: "dog"),
        .init(spanish: "casa", english: "house"),
        .init(spanish: "agua", english: "water"),
        .init(spanish: "sol", english: "sun"),
        .init(spanish: "luna", english: "moon"),
        .init(spanish: "libro", english: "book"),
        .init(spanish: "manzana", english: "apple"),
        .init(spanish: "árbol", english: "tree"),
        .init(spanish: "leche", english: "milk"),
        .init(spanish: "pan", english: "bread"),
        .init(spanish: "flor", english: "flower"),
        .init(spanish: "coche", english: "car"),
        .init(spanish: "playa", english: "beach"),
        .init(spanish: "amigo", english: "friend"),
        .init(spanish: "rojo", english: "red"),
        .init(spanish: "verde", english: "green"),
        .init(spanish: "grande", english: "big"),
        .init(spanish: "pequeño", english: "small"),
        .init(spanish: "feliz", english: "happy"),
    ]

    /// A quiz for `word` with 2 wrong English options drawn from the pool.
    static func quiz(for word: VocabWord) -> [String] {
        let wrong = all
            .filter { $0.id != word.id }
            .shuffled()
            .prefix(2)
            .map(\.english)
        return ([word.english] + wrong).shuffled()
    }
}
