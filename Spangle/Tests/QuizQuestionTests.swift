import Testing
@testable import Spangle

struct QuizQuestionTests {
    private let theme = Theme(name: "Test", english: "Test", emoji: "🧪", words: [
        VocabWord(spanish: "uno", english: "one"),
        VocabWord(spanish: "dos", english: "two"),
        VocabWord(spanish: "tres", english: "three"),
        VocabWord(spanish: "cuatro", english: "four"),
        VocabWord(spanish: "cinco", english: "five"),
    ])

    @Test
    func spanishToEnglishQuestionHasOneCorrectUniqueAnswer() throws {
        let word = try #require(theme.words.first)
        let question = theme.question(
            for: word,
            direction: .spanishToEnglish,
            heading: "Test"
        )

        #expect(question.prompt == "uno")
        #expect(question.correctAnswer == "one")
        #expect(question.options.count == 4)
        #expect(Set(question.options).count == question.options.count)
        #expect(question.options.count { $0 == question.correctAnswer } == 1)
    }

    @Test
    func englishToSpanishQuestionReversesPromptAndAnswers() throws {
        let word = try #require(theme.words.first)
        let question = theme.question(
            for: word,
            direction: .englishToSpanish,
            heading: "Test"
        )

        #expect(question.prompt == "one")
        #expect(question.correctAnswer == "uno")
        #expect(question.options.contains("uno"))
    }

    @Test
    func stableVocabularyIdentityIgnoresCaseAndAccents() {
        let first = VocabWord(spanish: "ÁRBOL", english: "Tree")
        let second = VocabWord(spanish: "arbol", english: "tree")
        #expect(first.id == second.id)
    }
}
