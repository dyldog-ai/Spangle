#if DEVELOPER_FEATURES
import Foundation
import Testing
@testable import SpangleDev

private final class TestLevelCloudStore: LevelCreatorCloudStore {
    var values: [String: Data] = [:]

    func data(forKey key: String) -> Data? { values[key] }
    func set(_ data: Data, forKey key: String) { values[key] = data }
    func synchronize() -> Bool { true }
}

struct LevelCreatorTests {
    @Test
    func vocabularyListReplacesWordCoins() throws {
        let words = try #require(CustomLevelDefinition.parseVocabulary("gato = cat\nperro = dog\nsol = sun\nluna = moon\nagua = water"))
        var definition = CustomLevelDefinition.empty

        definition.replaceVocabulary(with: words)

        #expect(definition.words == words)
        #expect(definition.objects.filter { $0.kind == .coin }.count == 5)
        #expect(definition.validationMessage == nil)
        #expect(CustomLevelDefinition.parseVocabulary("missing separator") == nil)
    }

    @Test
    func generatedVocabularyIsConfiguredWithoutPreGeneratingWords() {
        var definition = CustomLevelDefinition.empty
        for index in 0..<6 {
            definition.objects.append(.make(kind: .coin, x: 800 + Double(index * 500)))
        }
        definition.configureGeneratedVocabulary(prompt: "animals on a farm")

        #expect(definition.usesGeneratedVocabulary)
        #expect(definition.vocabularyPrompt == "animals on a farm")
        #expect(definition.words.isEmpty)
        #expect(definition.vocabularyCount == 6)
        #expect(definition.objects.filter { $0.kind == .coin }.count == 6)
        #expect(definition.validationMessage == nil)

        let generated = [
            VocabWord(spanish: "gato", english: "cat"),
            VocabWord(spanish: "perro", english: "dog"),
            VocabWord(spanish: "vaca", english: "cow"),
            VocabWord(spanish: "cerdo", english: "pig"),
            VocabWord(spanish: "pato", english: "duck"),
            VocabWord(spanish: "oveja", english: "sheep"),
        ]
        definition.applyGeneratedVocabulary(generated)
        #expect(definition.words == generated)
        #expect(definition.usesGeneratedVocabulary)
    }

    @Test
    func emptyDefinitionHasNoObjects() {
        let definition = CustomLevelDefinition.empty
        #expect(definition.objects.isEmpty)
        #expect(definition.words.isEmpty)
    }

    @Test
    func customDefinitionBuildsItsGap() throws {
        let words = try #require(CustomLevelDefinition.parseVocabulary("uno = one\ndos = two\ntres = three\ncuatro = four"))
        var definition = CustomLevelDefinition.empty
        definition.replaceVocabulary(with: words)
        definition.objects.append(.make(kind: .gap, x: 2_150))
        #expect(definition.validationMessage == nil)

        let level = definition.makeLevel()
        let gap = try #require(definition.objects.first { $0.kind == .gap })
        #expect(!level.hasGround(at: CGFloat(gap.x)))
        #expect(level.finishX == CGFloat(definition.finishX))
    }

    @MainActor @Test
    func savedDefinitionsPersist() throws {
        let suite = "LevelCreatorTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LevelCreatorStore(defaults: defaults, cloudStore: nil)
        var definition = CustomLevelDefinition.empty
        definition.title = "Saved Timeline"
        store.save(definition)
        definition.title = "Updated Timeline"
        store.save(definition)

        var restored = LevelCreatorStore(defaults: defaults, cloudStore: nil)
        #expect(restored.levels.count == 1)
        #expect(restored.levels.first?.title == "Updated Timeline")

        restored.delete(definition)
        restored = LevelCreatorStore(defaults: defaults, cloudStore: nil)
        #expect(restored.levels.isEmpty)
    }

    @MainActor @Test
    func cloudLevelsAreAvailableAcrossStores() throws {
        let cloud = TestLevelCloudStore()
        let firstSuite = "LevelCreatorCloudTests.first.\(UUID().uuidString)"
        let secondSuite = "LevelCreatorCloudTests.second.\(UUID().uuidString)"
        let firstDefaults = try #require(UserDefaults(suiteName: firstSuite))
        let secondDefaults = try #require(UserDefaults(suiteName: secondSuite))
        defer {
            firstDefaults.removePersistentDomain(forName: firstSuite)
            secondDefaults.removePersistentDomain(forName: secondSuite)
        }

        let firstDevice = LevelCreatorStore(defaults: firstDefaults, cloudStore: cloud)
        var definition = CustomLevelDefinition.empty
        definition.title = "Cloud Level"
        firstDevice.save(definition)

        let secondDevice = LevelCreatorStore(defaults: secondDefaults, cloudStore: cloud)
        #expect(secondDevice.levels.first?.title == "Cloud Level")

        secondDevice.delete(definition)
        firstDevice.reloadFromCloud()
        #expect(firstDevice.levels.isEmpty)
    }
}
#endif
