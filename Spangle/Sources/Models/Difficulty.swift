import CoreGraphics

/// Gameplay tuning for a single level. Higher levels run faster, have wider
/// gaps, shorter platforms and eventually double spikes. Jump feel (gravity /
/// jump velocity) stays constant so every gap remains fairly clearable.
struct Difficulty: Equatable {
    let worldSpeed: CGFloat
    let gap: CGFloat
    let segmentLength: CGFloat
    let doubleSpikes: Bool

    /// Scales smoothly with the zero-based level index.
    static func forLevel(_ i: Int) -> Difficulty {
        let f = CGFloat(i)
        return Difficulty(
            worldSpeed: min(640, 380 + f * 24),
            gap: min(340, 195 + f * 13),
            segmentLength: max(470, 780 - f * 28),
            doubleSpikes: i >= 5
        )
    }
}
