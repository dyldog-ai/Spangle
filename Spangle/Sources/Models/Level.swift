import CoreGraphics
import Foundation

/// Things that can appear in the world at a given horizontal position.
enum LevelItem {
    case spike(x: CGFloat)
    /// A word-coin at a height above the ground surface.
    case coin(x: CGFloat, y: CGFloat, word: VocabWord)
    /// A gate that quizzes one collected, not-yet-quizzed word.
    case gate(x: CGFloat)
    /// An automatic high-jump pad used before a longer gap.
    case spring(x: CGFloat)
    /// An optional collectible used to earn a three-star level rating.
    case challengeStar(x: CGFloat, y: CGFloat)
    /// A moving obstacle with a distinct movement pattern.
    case enemy(x: CGFloat, kind: EnemyKind)
    /// A raised surface that can be solid or collapse after landing.
    case platform(x: CGFloat, y: CGFloat, width: CGFloat, kind: PlatformKind)
    /// A visible updraft that carries airborne players.
    case wind(x: CGFloat, width: CGFloat)
    /// Absorbs one hazard hit.
    case shield(x: CGFloat, y: CGFloat)
    /// A safe restart point for the current run.
    case checkpoint(x: CGFloat)
}

/// A stretch of solid ground the player can stand on (world coordinates).
struct GroundSegment {
    let startX: CGFloat
    let endX: CGFloat
}

/// A procedurally-built level with progressive, hand-tuned obstacle patterns.
struct Level {
    static let challengeStarCount = 3

    let segments: [GroundSegment]
    let items: [LevelItem]
    let finishX: CGFloat

    private enum Pattern {
        case hurdle
        case doubleHurdle
        case rhythmRun
        case enemyRun
        case skyEnemy
        case platformHop
        case crumbleBridge
        case windLift
        case springGap
        case breather
        case gate
    }

    static func generate(
        words: [VocabWord],
        difficulty: Difficulty,
        seed: UInt64 = 0
    ) -> Level {
        guard !words.isEmpty else {
            return Level(
                segments: [GroundSegment(startX: -400, endX: 1_400)],
                items: [],
                finishX: 1_000
            )
        }

        var segments = [GroundSegment(startX: -400, endX: 900)]
        var items: [LevelItem] = []
        var x: CGFloat = 900

        var generator = SeededGenerator(seed: seed)
        let pool = words.shuffled(using: &generator)
        let chunkCount = max(8, pool.count)
        let starChunks = challengeStarChunks(in: chunkCount)
        let checkpointChunk = chunkCount / 2
        let patterns = availablePatterns(for: difficulty).shuffled(using: &generator)
        var patternIndex = 0

        for i in 0..<chunkCount {
            let pattern: Pattern
            if i % 4 == 3 {
                pattern = .gate
            } else {
                pattern = patterns[patternIndex % patterns.count]
                patternIndex += 1
            }
            let segmentLength = length(for: pattern, difficulty: difficulty)
            let segment = GroundSegment(startX: x, endX: x + segmentLength)
            segments.append(segment)

            let gapAfter = populate(
                pattern,
                segment: segment,
                gap: difficulty.gap,
                word: pool[i % pool.count],
                includesStar: starChunks.contains(i),
                items: &items
            )
            if i == checkpointChunk {
                items.append(.checkpoint(x: segment.startX + segmentLength * 0.05))
            }
            if difficulty.supportsShields && i == 1 {
                items.append(.shield(x: segment.startX + segmentLength * 0.22, y: 92))
            }
            x = segment.endX + gapAfter
        }

        let finish = x + 600
        segments.append(GroundSegment(startX: x, endX: finish + 400))
        return Level(segments: segments, items: items, finishX: finish)
    }

    /// Whether solid ground exists at `worldX`.
    func hasGround(at worldX: CGFloat) -> Bool {
        segments.contains { worldX >= $0.startX && worldX <= $0.endX }
    }

    private static func availablePatterns(for difficulty: Difficulty) -> [Pattern] {
        var patterns: [Pattern] = [.hurdle]
        if difficulty.supportsDoubleHurdles { patterns.append(.doubleHurdle) }
        if difficulty.supportsRhythmRuns { patterns.append(.rhythmRun) }
        if difficulty.supportsEnemies { patterns.append(.enemyRun) }
        if difficulty.supportsPlatforms { patterns.append(.platformHop) }
        if difficulty.supportsFlyingEnemies { patterns.append(.skyEnemy) }
        if difficulty.supportsCrumblingPlatforms { patterns.append(.crumbleBridge) }
        if difficulty.supportsWindLifts { patterns.append(.windLift) }
        if difficulty.supportsSpringGaps { patterns.append(.springGap) }
        patterns.append(.breather)
        return patterns
    }

    private static func length(for pattern: Pattern, difficulty: Difficulty) -> CGFloat {
        switch pattern {
        case .gate:
            return max(difficulty.segmentLength, difficulty.worldSpeed * 0.9)
        case .rhythmRun:
            return max(difficulty.segmentLength * 1.35, 780)
        case .enemyRun, .skyEnemy:
            return max(difficulty.segmentLength, 650)
        case .platformHop, .crumbleBridge, .windLift, .springGap:
            return max(difficulty.segmentLength, 620)
        case .breather:
            return max(difficulty.segmentLength * 0.82, 500)
        case .hurdle, .doubleHurdle:
            return difficulty.segmentLength
        }
    }

    /// Adds a pattern's objects and returns the gap following its platform.
    private static func populate(
        _ pattern: Pattern,
        segment: GroundSegment,
        gap: CGFloat,
        word: VocabWord,
        includesStar: Bool,
        items: inout [LevelItem]
    ) -> CGFloat {
        let length = segment.endX - segment.startX
        let position: (CGFloat) -> CGFloat = { segment.startX + length * $0 }
        var starPosition = CGPoint(x: position(0.7), y: 170)
        var gapAfter = gap

        switch pattern {
        case .hurdle:
            items.append(.spike(x: position(0.58)))
            items.append(.coin(x: position(0.58), y: 128, word: word))
            starPosition = CGPoint(x: position(0.76), y: 150)

        case .doubleHurdle:
            items.append(.spike(x: position(0.54)))
            items.append(.spike(x: position(0.64)))
            items.append(.coin(x: position(0.59), y: 158, word: word))
            starPosition = CGPoint(x: position(0.59), y: 220)

        case .rhythmRun:
            items.append(.spike(x: position(0.34)))
            items.append(.spike(x: position(0.72)))
            items.append(.coin(x: position(0.72), y: 138, word: word))
            starPosition = CGPoint(x: position(0.52), y: 190)

        case .enemyRun:
            items.append(.enemy(x: position(0.48), kind: .trickster))
            items.append(.enemy(x: position(0.72), kind: .hopper))
            items.append(.coin(x: position(0.6), y: 155, word: word))
            starPosition = CGPoint(x: position(0.82), y: 190)

        case .skyEnemy:
            items.append(.enemy(x: position(0.58), kind: .flyer))
            items.append(.coin(x: position(0.58), y: 245, word: word))
            starPosition = CGPoint(x: position(0.8), y: 205)

        case .platformHop:
            gapAfter = gap * 1.55
            items.append(.platform(x: segment.endX + gapAfter * 0.32, y: 78,
                                   width: 125, kind: .solid))
            items.append(.platform(x: segment.endX + gapAfter * 0.7, y: 125,
                                   width: 120, kind: .solid))
            items.append(.coin(x: segment.endX + gapAfter * 0.69, y: 195, word: word))
            starPosition = CGPoint(x: segment.endX + gapAfter * 0.35, y: 155)

        case .crumbleBridge:
            gapAfter = gap * 1.5
            for fraction in [0.22, 0.5, 0.78] as [CGFloat] {
                items.append(.platform(x: segment.endX + gapAfter * fraction,
                                       y: 70 + abs(0.5 - fraction) * 90,
                                       width: 105, kind: .crumbling))
            }
            items.append(.coin(x: segment.endX + gapAfter * 0.5, y: 175, word: word))
            starPosition = CGPoint(x: segment.endX + gapAfter * 0.78, y: 180)

        case .windLift:
            gapAfter = gap * 1.55
            items.append(.spring(x: position(0.82)))
            items.append(.wind(x: segment.endX - 40, width: gapAfter + 120))
            items.append(.platform(x: segment.endX + gapAfter * 0.6, y: 215,
                                   width: 145, kind: .solid))
            items.append(.coin(x: segment.endX + gapAfter * 0.6, y: 285, word: word))
            starPosition = CGPoint(x: segment.endX + gapAfter * 0.82, y: 315)

        case .springGap:
            gapAfter = gap * 1.35
            items.append(.spring(x: position(0.82)))
            items.append(.coin(
                x: segment.endX + gapAfter * 0.43,
                y: 350,
                word: word
            ))
            starPosition = CGPoint(
                x: segment.endX + gapAfter * 0.68,
                y: 350
            )

        case .breather:
            items.append(.coin(x: position(0.5), y: 68, word: word))
            starPosition = CGPoint(x: position(0.72), y: 185)

        case .gate:
            // Keep teaching collectibles visually clear of the tall gate flag,
            // especially on compact iPhone landscapes where markers scale.
            items.append(.gate(x: position(0.14)))
            items.append(.coin(x: position(0.68), y: 82, word: word))
            starPosition = CGPoint(x: position(0.84), y: 160)
        }

        if includesStar {
            items.append(.challengeStar(x: starPosition.x, y: starPosition.y))
        }
        return gapAfter
    }

    private static func challengeStarChunks(in chunkCount: Int) -> Set<Int> {
        Set([1, chunkCount / 2, max(0, chunkCount - 2)])
    }
}
