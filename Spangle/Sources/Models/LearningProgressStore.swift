import Foundation

/// Local, offline-first spaced-practice history for every stable vocabulary pair.
final class LearningProgressStore {
    private let defaults: UserDefaults
    private let storageKey: String
    private(set) var records: [String: LearningRecord]

    init(defaults: UserDefaults = .standard, storageKey: String = "learningProgress.v1") {
        self.defaults = defaults
        self.storageKey = storageKey
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: LearningRecord].self, from: data) {
            records = decoded
        } else {
            records = [:]
        }
    }

    var totalAnswers: Int { records.values.reduce(0) { $0 + $1.attempts } }
    var correctAnswers: Int { records.values.reduce(0) { $0 + $1.correctAnswers } }
    var masteredCount: Int { records.values.count { $0.masteryLevel >= 4 } }
    var learningCount: Int { records.values.count { $0.exposures > 0 && $0.masteryLevel < 4 } }
    var dueCount: Int { records.values.count { $0.isDue() } }
    var accuracy: Double {
        totalAnswers == 0 ? 0 : Double(correctAnswers) / Double(totalAnswers)
    }

    func recordExposure(to word: VocabWord) {
        var record = record(for: word)
        record.exposures += 1
        records[word.id] = record
        save()
    }

    func recordAnswer(to word: VocabWord, direction: QuizQuestion.Direction, correct: Bool) {
        var record = record(for: word)
        if correct {
            record.correctAnswers += 1
            record.currentStreak += 1
        } else {
            record.incorrectAnswers += 1
            record.currentStreak = 0
        }
        switch direction {
        case .spanishToEnglish:
            record.spanishToEnglishAttempts += 1
        case .englishToSpanish:
            record.englishToSpanishAttempts += 1
        }
        record.lastPractised = .now
        records[word.id] = record
        save()
    }

    func preferredDirection(for word: VocabWord) -> QuizQuestion.Direction {
        let record = record(for: word)
        return record.spanishToEnglishAttempts <= record.englishToSpanishAttempts
            ? .spanishToEnglish
            : .englishToSpanish
    }

    func reviewWords(from words: [VocabWord], limit: Int = 12) -> [VocabWord] {
        words.sorted { lhs, rhs in
            let left = record(for: lhs)
            let right = record(for: rhs)
            if left.isDue() != right.isDue() { return left.isDue() }
            if left.masteryLevel != right.masteryLevel { return left.masteryLevel < right.masteryLevel }
            return left.attempts < right.attempts
        }
        .prefix(limit)
        .map { $0 }
    }

    func reset() {
        records.removeAll()
        defaults.removeObject(forKey: storageKey)
    }

    private func record(for word: VocabWord) -> LearningRecord {
        records[word.id] ?? LearningRecord(spanish: word.spanish, english: word.english)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
