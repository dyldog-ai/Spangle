#if DEVELOPER_FEATURES
import Foundation
import Testing
@testable import SpangleDev

struct LevelCreatorTests {
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

        let restored = LevelCreatorStore(defaults: defaults)
        #expect(restored.levels.first?.title == "Saved Timeline")
    }
}
#endif
