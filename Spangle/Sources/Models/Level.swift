import CoreGraphics
import Foundation

/// Things that can appear in the world at a given horizontal position.
enum LevelItem {
    case spike(x: CGFloat)
    /// A word-coin floating above the ground.
    case coin(x: CGFloat, word: VocabWord)
    /// A gate that quizzes one collected, not-yet-quizzed word.
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

    static func generate(words: [VocabWord], difficulty: Difficulty) -> Level {
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
            let isGateChunk = (i % 3 == 2)
            // Gate chunks provide a long hazard-free runway after the quiz,
            // including at the highest scroll speeds.
            let gateRunwayLength = difficulty.worldSpeed * 0.9
            let segLen = isGateChunk
                ? max(difficulty.segmentLength, gateRunwayLength)
                : difficulty.segmentLength
            let seg = GroundSegment(startX: x, endX: x + segLen)
            segments.append(seg)

            if isGateChunk {
                // Place the gate early so answering never resumes on the edge
                // of the next gap.
                items.append(.gate(x: x + segLen * 0.25))
            } else {
                // One or two spikes partway along the segment. A double pair sits
                // close together so a single well-timed jump clears both.
                items.append(.spike(x: x + segLen * 0.55))
                if difficulty.doubleSpikes {
                    items.append(.spike(x: x + segLen * 0.66))
                }
            }

            // A collectible word-coin near the segment start (before any gate).
            let word = pool[wordIndex % pool.count]
            wordIndex += 1
            items.append(.coin(x: x + segLen * 0.28, word: word))

            x = seg.endX
            x += difficulty.gap // jumpable gap, widens with difficulty
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
