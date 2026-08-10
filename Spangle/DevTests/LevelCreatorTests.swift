#if DEVELOPER_FEATURES
import Foundation
import Testing
@testable import SpangleDev

struct LevelCreatorTests {
    @Test
    func vocabularyListReplacesWordCoins() throws {
        let words = try #require(CustomLevelDefinition.parseVocabulary("gato = cat\nperro = dog\nsol = sun\nluna = moon\nagua = water"))
        var definition = CustomLevelDefinition.starter

        definition.replaceVocabulary(with: words)

        #expect(definition.words == words)
        #expect(definition.objects.filter { $0.kind == .coin }.count == 5)
        #expect(definition.validationMessage == nil)
        #expect(CustomLevelDefinition.parseVocabulary("missing separator") == nil)
    }

    @Test
    func starterDefinitionIsPlayableAndBuildsItsGap() throws {
        let definition = CustomLevelDefinition.starter
        #expect(definition.validationMessage == nil)
        #expect(definition.words.count >= 4)

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
        let store = LevelCreatorStore(defaults: defaults)
        var definition = CustomLevelDefinition.starter
        definition.title = "Saved Timeline"
        store.save(definition)
        definition.title = "Updated Timeline"
        store.save(definition)

        var restored = LevelCreatorStore(defaults: defaults)
        #expect(restored.levels.count == 1)
        #expect(restored.levels.first?.title == "Updated Timeline")

        restored.delete(definition)
        restored = LevelCreatorStore(defaults: defaults)
        #expect(restored.levels.isEmpty)
    }
}
#endif
