#if DEVELOPER_FEATURES
import Foundation
import Testing
@testable import SpangleDev

struct DeveloperSettingsTests {
    @MainActor @Test
    func allSkinsCanBeUnlockedWithoutSpendingStars() throws {
        let suite = "DeveloperSkinTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CharacterStore(defaults: defaults)
        store.deposit(stars: 25)

        store.unlockAllDesigns()

        #expect(store.ownedIDs == Set(CharacterCatalog.all.map(\.id)))
        #expect(store.starBalance == 25)
    }

    @MainActor @Test
    func campaignUnlockControlsAreReversible() throws {
        let suite = "DeveloperSettingsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let unlockedThrough = GameViewModel.setDeveloperLevelsUnlocked(true, defaults: defaults)
        #expect(unlockedThrough == Campaign.themes.count - 1)
        #expect(defaults.integer(forKey: "highestUnlockedLevel") == Campaign.themes.count - 1)

        let clearedThrough = GameViewModel.setDeveloperLevelsUnlocked(false, defaults: defaults)
        #expect(clearedThrough == 0)
        #expect(defaults.object(forKey: "highestUnlockedLevel") == nil)
    }
}
#endif
