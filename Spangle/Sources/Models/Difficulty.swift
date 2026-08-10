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
    var supportsSpringGaps: Bool { patternTier >= 3 }

    /// Scales smoothly with the zero-based level index while introducing a new
    /// layout mechanic in each of the first four levels.
    static func forLevel(_ i: Int) -> Difficulty {
        let f = CGFloat(i)
        return Difficulty(
            worldSpeed: min(640, 380 + f * 24),
            gap: min(340, 195 + f * 13),
            segmentLength: max(470, 780 - f * 28),
            patternTier: min(3, max(0, i))
        )
    }
}
