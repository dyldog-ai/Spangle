import Foundation
import Testing
@testable import Spangle

struct LearningProgressStoreTests {
    @Test
    func answersPersistAndChangePreferredDirection() throws {
        let suite = "LearningProgressStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let word = VocabWord(spanish: "árbol", english: "tree")

        let store = LearningProgressStore(defaults: defaults, storageKey: "progress")
        #expect(store.preferredDirection(for: word) == .spanishToEnglish)
        store.recordExposure(to: word)
        store.recordAnswer(to: word, direction: .spanishToEnglish, correct: true)
        #expect(store.preferredDirection(for: word) == .englishToSpanish)

        let reloaded = LearningProgressStore(defaults: defaults, storageKey: "progress")
        #expect(reloaded.totalAnswers == 1)
        #expect(reloaded.correctAnswers == 1)
        #expect(reloaded.learningCount == 1)
        #expect(reloaded.accuracy == 1)
    }

    @Test
    func reviewPrioritizesWeakWords() throws {
        let suite = "LearningProgressStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let strong = VocabWord(spanish: "uno", english: "one")
        let weak = VocabWord(spanish: "dos", english: "two")
        let store = LearningProgressStore(defaults: defaults, storageKey: "progress")

        for _ in 0..<6 {
            store.recordAnswer(to: strong, direction: .spanishToEnglish, correct: true)
        }
        store.recordAnswer(to: weak, direction: .spanishToEnglish, correct: false)

        #expect(store.reviewWords(from: [strong, weak]).first == weak)
        #expect(store.records[strong.id]?.masteryLevel == 5)
        #expect(store.records[weak.id]?.masteryLevel == 0)
    }

    @Test
    func resetRemovesStoredLearningHistory() throws {
        let suite = "LearningProgressStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LearningProgressStore(defaults: defaults, storageKey: "progress")
        store.recordExposure(to: VocabWord(spanish: "sol", english: "sun"))

        store.reset()

        #expect(store.records.isEmpty)
        #expect(defaults.data(forKey: "progress") == nil)
    }
}
