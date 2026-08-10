import Foundation
import Testing
@testable import Spangle

struct QuizWordQueueTests {
    @Test
    func collectedWordsRemainAvailableUntilEachHasBeenQuizzed() throws {
        let first = VocabWord(spanish: "uno", english: "one")
        let second = VocabWord(spanish: "dos", english: "two")
        var queue = QuizWordQueue()

        queue.collect(first)
        queue.collect(second)

        let next = queue.takeRandom()
        let quizzed = try #require(next)
        #expect([first.id, second.id].contains(quizzed.id))
        #expect(queue.words.count == 1)
        #expect(queue.words[0].id != quizzed.id)
    }

    @Test
    func finalQuizQueueContainsEveryLevelWordExactlyOnce() {
        let words = [
            VocabWord(spanish: "uno", english: "one"),
            VocabWord(spanish: "dos", english: "two"),
            VocabWord(spanish: "tres", english: "three"),
        ]
        var queue = QuizWordQueue(words: words)
        var quizzedIDs: Set<String> = []

        while let word = queue.takeRandom() {
            quizzedIDs.insert(word.id)
        }

        #expect(quizzedIDs == Set(words.map(\.id)))
        #expect(queue.count == 0)
    }

    @Test
    func collectingTheSameWordTwiceDoesNotQueueDuplicateQuizzes() {
        let word = VocabWord(spanish: "uno", english: "one")
        var queue = QuizWordQueue()

        queue.collect(word)
        queue.collect(word)

        #expect(queue.words.count == 1)
    }
}
