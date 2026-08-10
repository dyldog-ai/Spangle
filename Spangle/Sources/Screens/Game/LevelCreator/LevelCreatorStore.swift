#if DEVELOPER_FEATURES
import Foundation
import SwiftUI

@MainActor
final class LevelCreatorStore: ObservableObject {
    @Published private(set) var levels: [CustomLevelDefinition]

    private let defaults: UserDefaults
    private let storageKey = "developer.customLevels.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let stored = try? JSONDecoder().decode([CustomLevelDefinition].self, from: data) {
            levels = stored
        } else {
            levels = []
        }
    }

    func save(_ definition: CustomLevelDefinition) {
        if let index = levels.firstIndex(where: { $0.id == definition.id }) {
            levels[index] = definition
        } else {
            levels.append(definition)
        }
        persist()
    }

    func delete(_ definition: CustomLevelDefinition) {
        levels.removeAll { $0.id == definition.id }
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(levels) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
#endif
