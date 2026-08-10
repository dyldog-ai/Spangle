import Combine
import Foundation

/// Persistent, offline star wallet and character wardrobe.
@MainActor
final class CharacterStore: ObservableObject {
    @Published private(set) var starBalance: Int
    @Published private(set) var ownedIDs: Set<String>
    @Published private(set) var selectedID: String

    let designs = CharacterCatalog.all

    private let defaults: UserDefaults
    private let balanceKey = "characters.starBalance"
    private let ownedKey = "characters.owned"
    private let selectedKey = "characters.selected"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: balanceKey) == nil {
            // Existing players begin with credit for their previously earned
            // best ratings; future completed runs are repeatable earnings.
            starBalance = defaults.dictionaryRepresentation().reduce(into: 0) { total, entry in
                guard entry.key.hasPrefix("challengeStarRating."),
                      let value = entry.value as? NSNumber else { return }
                total += max(0, value.intValue)
            }
        } else {
            starBalance = max(0, defaults.integer(forKey: balanceKey))
        }
        let storedOwned = defaults.stringArray(forKey: ownedKey) ?? []
        let initialOwned = Set(storedOwned).union([CharacterCatalog.original.id])
        ownedIDs = initialOwned
        let storedSelected = defaults.string(forKey: selectedKey) ?? CharacterCatalog.original.id
        selectedID = initialOwned.contains(storedSelected) ? storedSelected : CharacterCatalog.original.id
    }

    var selected: CharacterDesign {
        designs.first { $0.id == selectedID } ?? CharacterCatalog.original
    }

    func owns(_ design: CharacterDesign) -> Bool {
        ownedIDs.contains(design.id)
    }

    func canAfford(_ design: CharacterDesign) -> Bool {
        starBalance >= design.cost
    }

    @discardableResult
    func purchase(_ design: CharacterDesign) -> Bool {
        guard !owns(design), canAfford(design) else { return false }
        starBalance -= design.cost
        ownedIDs.insert(design.id)
        selectedID = design.id
        save()
        return true
    }

    func equip(_ design: CharacterDesign) {
        guard owns(design) else { return }
        selectedID = design.id
        save()
    }

    func deposit(stars: Int) {
        guard stars > 0 else { return }
        starBalance += stars
        save()
    }

    #if DEVELOPER_FEATURES
    func unlockAllDesigns() {
        ownedIDs = Set(designs.map(\.id))
        save()
    }
    #endif

    func reset() {
        starBalance = 0
        ownedIDs = [CharacterCatalog.original.id]
        selectedID = CharacterCatalog.original.id
        save()
    }

    private func save() {
        defaults.set(starBalance, forKey: balanceKey)
        defaults.set(ownedIDs.sorted(), forKey: ownedKey)
        defaults.set(selectedID, forKey: selectedKey)
    }
}
