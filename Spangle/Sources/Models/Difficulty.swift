import CoreGraphics

/// Gameplay tuning for a single level. Higher levels run faster, have wider
/// gaps, shorter platforms and unlock more involved obstacle patterns. Jump
/// feel stays constant so ordinary gaps remain fairly clearable.
struct Difficulty: Equatable {
    let worldSpeed: CGFloat
    let gap: CGFloat
    let segmentLength: CGFloat
    let patternTier: Int

    var supportsDoubleHurdles: Bool { patternTier >= 1 }
    var supportsRhythmRuns: Bool { patternTier >= 2 }
    var supportsEnemies: Bool { patternTier >= 2 }
    var supportsPlatforms: Bool { patternTier >= 1 }
    var supportsSpringGaps: Bool { patternTier >= 3 }
    var supportsFlyingEnemies: Bool { patternTier >= 3 }
    var supportsCrumblingPlatforms: Bool { patternTier >= 4 }
    var supportsWindLifts: Bool { patternTier >= 5 }
    var supportsShields: Bool { patternTier >= 3 }
    var supportsShieldGauntlets: Bool { patternTier >= 12 }
    var supportsStompChains: Bool { patternTier >= 13 }
    var supportsPrecisionBridges: Bool { patternTier >= 15 }
    var supportsWindMazes: Bool { patternTier >= 17 }

    /// Scales smoothly with the zero-based level index while introducing a new
    /// layout mechanic in each of the first four levels.
    static func forLevel(_ i: Int) -> Difficulty {
        let f = CGFloat(i)
        return Difficulty(
            worldSpeed: min(700, 380 + f * 24),
            gap: min(370, 195 + f * 13),
            segmentLength: max(430, 780 - f * 28),
            patternTier: max(0, i)
        )
    }
}
