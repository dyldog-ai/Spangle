import CoreGraphics
import Foundation

/// Things that can appear in the world at a given horizontal position.
enum LevelItem {
    case spike(x: CGFloat)
    /// A word-coin floating above the ground.
    case coin(x: CGFloat, word: VocabWord)
    /// A gate that quizzes the most recently collected word.
    case gate(x: CGFloat)
}

/// A stretch of solid ground the player can stand on (world coordinates).
struct GroundSegment {
    let startX: CGFloat
    let endX: CGFloat
}

/// A procedurally-built level: alternating ground segments (with gaps),
/// spikes, word-coins and quiz gates.
struct Level {
    let segments: [GroundSegment]
    let items: [LevelItem]
    let finishX: CGFloat

    static func generate(words: [VocabWord]) -> Level {
        var segments: [GroundSegment] = []
        var items: [LevelItem] = []

        var x: CGFloat = 0
        let startPad: CGFloat = 900 // safe runway before first hazard
        segments.append(GroundSegment(startX: -400, endX: startPad))
        x = startPad

        let pool = words.shuffled()
        var wordIndex = 0

        // Each "chunk" is a ground segment holding a hazard and a word-coin,
        // followed by a gap, with a quiz gate every few chunks.
        let chunkCount = max(6, pool.count)
        for i in 0..<chunkCount {
            let segLen: CGFloat = 700
            let seg = GroundSegment(startX: x, endX: x + segLen)
            segments.append(seg)

            // A spike partway along the segment.
            items.append(.spike(x: x + segLen * 0.55))

            // A collectible word-coin near the segment start.
            let word = pool[wordIndex % pool.count]
            wordIndex += 1
            items.append(.coin(x: x + segLen * 0.28, word: word))

            // A quiz gate at the end of every third chunk.
            if i % 3 == 2 {
                items.append(.gate(x: x + segLen * 0.9))
            }

            x = seg.endX
            let gap: CGFloat = 220 // jumpable gap
            x += gap
        }

        // Final safe landing + finish line.
        let finish = x + 600
        segments.append(GroundSegment(startX: x, endX: finish + 400))
        return Level(segments: segments, items: items, finishX: finish)
    }

    /// Whether solid ground exists at `worldX`.
    func hasGround(at worldX: CGFloat) -> Bool {
        segments.contains { worldX >= $0.startX && worldX <= $0.endX }
    }
}
