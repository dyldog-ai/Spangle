/// Tracks collected words that have not been quizzed yet.
struct QuizWordQueue {
    private(set) var words: [VocabWord] = []

    mutating func collect(_ word: VocabWord) {
        guard !words.contains(where: { $0.id == word.id }) else { return }
        words.append(word)
    }

    mutating func takeRandom() -> VocabWord? {
        guard let index = words.indices.randomElement() else { return nil }
        return words.remove(at: index)
    }

    mutating func removeAll() {
        words.removeAll()
    }
}
