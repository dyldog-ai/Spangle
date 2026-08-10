import Foundation
import Testing
@testable import Spangle

struct CharacterStoreTests {
    @MainActor @Test
    func existingRatingsSeedTheInitialWallet() throws {
        let suite = "CharacterStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(3, forKey: "challengeStarRating.one")
        defaults.set(2, forKey: "challengeStarRating.two")

        let store = CharacterStore(defaults: defaults)

        #expect(store.starBalance == 5)
    }

    @MainActor @Test
    func starsPurchaseAndSelectionPersist() throws {
        let suite = "CharacterStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CharacterStore(defaults: defaults)
        let coral = try #require(CharacterCatalog.all.first { $0.style == .coral })

        #expect(store.selected == CharacterCatalog.original)
        #expect(!store.purchase(coral))

        store.deposit(stars: 8)
        #expect(store.purchase(coral))
        #expect(store.starBalance == 3)
        #expect(store.owns(coral))
        #expect(store.selected == coral)

        let restored = CharacterStore(defaults: defaults)
        #expect(restored.starBalance == 3)
        #expect(restored.owns(coral))
        #expect(restored.selected == coral)
    }

    @MainActor @Test
    func resetClearsWalletAndWardrobe() throws {
        let suite = "CharacterStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CharacterStore(defaults: defaults)
        let coral = try #require(CharacterCatalog.all.first { $0.style == .coral })
        store.deposit(stars: coral.cost)
        #expect(store.purchase(coral))

        store.reset()

        #expect(store.starBalance == 0)
        #expect(store.ownedIDs == Set([CharacterCatalog.original.id]))
        #expect(store.selected == CharacterCatalog.original)
    }
}
