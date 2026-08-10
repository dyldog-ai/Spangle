import SwiftUI

@MainActor
final class GameSettings: ObservableObject {
    @Published var soundEnabled: Bool { didSet { save(soundEnabled, for: soundKey) } }
    @Published var hapticsEnabled: Bool { didSet { save(hapticsEnabled, for: hapticsKey) } }
    @Published var reducedMotion: Bool { didSet { save(reducedMotion, for: reducedMotionKey) } }
    @Published var highContrast: Bool { didSet { save(highContrast, for: highContrastKey) } }

    private let defaults: UserDefaults
    private let soundKey = "settings.sound"
    private let hapticsKey = "settings.haptics"
    private let reducedMotionKey = "settings.reducedMotion"
    private let highContrastKey = "settings.highContrast"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        soundEnabled = defaults.object(forKey: soundKey) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: hapticsKey) as? Bool ?? true
        reducedMotion = defaults.object(forKey: reducedMotionKey) as? Bool ?? false
        highContrast = defaults.object(forKey: highContrastKey) as? Bool ?? false
    }

    private func save(_ value: Bool, for key: String) {
        defaults.set(value, forKey: key)
    }
}
