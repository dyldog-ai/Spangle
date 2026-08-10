#if DEVELOPER_FEATURES
import Foundation
import SwiftUI

protocol LevelCreatorCloudStore: AnyObject {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: LevelCreatorCloudStore {
    func set(_ data: Data, forKey key: String) {
        set(data as Any, forKey: key)
    }
}

@MainActor
final class LevelCreatorStore: NSObject, ObservableObject {
    @Published private(set) var levels: [CustomLevelDefinition]

    private let defaults: UserDefaults
    private let cloudStore: (any LevelCreatorCloudStore)?
    private static let storageKey = "developer.customLevels.v1"
    private var cloudObserver: NSObjectProtocol?

    init(
        defaults: UserDefaults = .standard,
        cloudStore: (any LevelCreatorCloudStore)? = NSUbiquitousKeyValueStore.default
    ) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        cloudStore?.synchronize()

        let cloudLevels = cloudStore
            .flatMap { $0.data(forKey: Self.storageKey) }
            .flatMap(Self.decodeLevels)
        let localLevels = defaults.data(forKey: Self.storageKey).flatMap(Self.decodeLevels)
        levels = cloudLevels ?? localLevels ?? []
        super.init()

        if cloudLevels == nil, !levels.isEmpty {
            persist()
        }
        if let cloudStore {
            cloudObserver = NotificationCenter.default.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: cloudStore,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in self?.reloadFromCloud() }
            }
        }
    }

    deinit {
        if let cloudObserver { NotificationCenter.default.removeObserver(cloudObserver) }
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

    func reloadFromCloud() {
        guard let data = cloudStore?.data(forKey: Self.storageKey),
              let cloudLevels = Self.decodeLevels(data),
              cloudLevels != levels else { return }
        levels = cloudLevels
        defaults.set(data, forKey: Self.storageKey)
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(levels) else { return }
        defaults.set(data, forKey: Self.storageKey)
        cloudStore?.set(data, forKey: Self.storageKey)
        cloudStore?.synchronize()
    }

    private static func decodeLevels(_ data: Data) -> [CustomLevelDefinition]? {
        try? JSONDecoder().decode([CustomLevelDefinition].self, from: data)
    }
}
#endif
