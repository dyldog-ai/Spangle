import Testing
@testable import Spangle

struct AdvancedMechanicsTests {
    @Test
    func lateGameUsesAllEnemyAndPlatformInteractions() {
        let words = Campaign.themes.flatMap(\.words)
        let level = Level.generate(words: words, difficulty: .forLevel(11), seed: 42)
        var enemyKinds = Set<String>()
        var solidPlatforms = 0
        var crumblingPlatforms = 0
        var winds = 0

        for item in level.items {
            switch item {
            case let .enemy(_, kind):
                enemyKinds.insert(String(describing: kind))
            case let .platform(_, y, width, kind):
                #expect(y > 0 && y <= 350)
                #expect(width >= 100)
                if kind == .solid { solidPlatforms += 1 } else { crumblingPlatforms += 1 }
            case .wind:
                winds += 1
            default:
                break
            }
        }

        #expect(enemyKinds == Set(["trickster", "hopper", "flyer"]))
        #expect(solidPlatforms > 0)
        #expect(crumblingPlatforms > 0)
        #expect(winds > 0)
    }
}
