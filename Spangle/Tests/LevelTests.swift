import CoreGraphics
import Testing
@testable import Spangle

struct LevelTests {
    private let words = (0..<8).map {
        VocabWord(spanish: "palabra \($0)", english: "word \($0)")
    }

    @Test
    func gateFlagsStayClearOfWordCoins() {
        for seed in 0..<20 {
            let level = Level.generate(words: words, difficulty: .forLevel(11), seed: UInt64(seed))
            let gates = level.items.compactMap { item -> CGFloat? in
                guard case let .gate(x) = item else { return nil }
                return x
            }
            let coins = level.items.compactMap { item -> CGFloat? in
                guard case let .coin(x, _, _) = item else { return nil }
                return x
            }

            for gate in gates {
                #expect(coins.allSatisfy { abs($0 - gate) >= 150 })
            }
        }
    }

    @Test
    func highSpeedGatesLeaveEnoughRunwayWithoutPausingScroll() throws {
        let difficulty = Difficulty.forLevel(20)
        let level = Level.generate(words: words, difficulty: difficulty)
        let gatePositions = level.items.compactMap { item -> CGFloat? in
            guard case let .gate(x) = item else { return nil }
            return x
        }

        #expect(!gatePositions.isEmpty)
        for gateX in gatePositions {
            let segment = try #require(level.segments.first {
                gateX >= $0.startX && gateX <= $0.endX
            })
            let availableReactionTime = (segment.endX - gateX) / difficulty.worldSpeed
            #expect(availableReactionTime >= 0.65)
        }
    }

    @Test
    func everyLevelHasThreeOptionalStarsAndEveryVocabularyWord() {
        for levelIndex in [0, 3, 11, 20] {
            let level = Level.generate(words: words, difficulty: .forLevel(levelIndex))
            let starCount = level.items.count { item in
                guard case .challengeStar = item else { return false }
                return true
            }
            let vocabulary = Set<String>(level.items.compactMap { item -> String? in
                guard case let .coin(_, _, word) = item else { return nil }
                return word.spanish
            })

            #expect(starCount == Level.challengeStarCount)
            #expect(vocabulary == Set(words.map(\.spanish)))
        }
    }

    @Test
    func differentSeedsRandomizeCoinOrder() {
        let first = Level.generate(words: words, difficulty: .forLevel(4), seed: 1)
        let second = Level.generate(words: words, difficulty: .forLevel(4), seed: 2)
        let firstOrder = first.items.compactMap { item -> String? in
            guard case let .coin(_, _, word) = item else { return nil }
            return word.id
        }
        let secondOrder = second.items.compactMap { item -> String? in
            guard case let .coin(_, _, word) = item else { return nil }
            return word.id
        }

        #expect(firstOrder != secondOrder)
    }

    @Test
    func sameSeedProducesTheSameLevel() {
        let first = Level.generate(words: words, difficulty: .forLevel(8), seed: 42)
        let second = Level.generate(words: words, difficulty: .forLevel(8), seed: 42)

        #expect(first.finishX == second.finishX)
        #expect(first.segments.map { [$0.startX, $0.endX] }
            == second.segments.map { [$0.startX, $0.endX] })
        #expect(itemDescriptions(first.items) == itemDescriptions(second.items))
    }

    @Test
    func advancedLevelsContainRecoveryAndPowerMechanics() {
        let level = Level.generate(words: words, difficulty: .forLevel(8), seed: 7)
        let checkpoints = level.items.count { if case .checkpoint = $0 { true } else { false } }
        let shields = level.items.count { if case .shield = $0 { true } else { false } }
        let enemies = level.items.count { if case .enemy = $0 { true } else { false } }

        #expect(checkpoints == 1)
        #expect(shields == 1)
        #expect(enemies > 0)
    }

    @Test
    func mechanicsAndLayoutsBecomeMoreVaried() throws {
        let firstLevel = Level.generate(words: words, difficulty: .forLevel(0))
        let advancedDifficulty = Difficulty.forLevel(6)
        let advancedLevel = Level.generate(words: words, difficulty: advancedDifficulty)

        let firstLevelSprings = firstLevel.items.count { item in
            guard case .spring = item else { return false }
            return true
        }
        let advancedSprings = advancedLevel.items.compactMap { item -> CGFloat? in
            guard case let .spring(x) = item else { return nil }
            return x
        }
        let advancedCoinHeights = Set(advancedLevel.items.compactMap { item -> CGFloat? in
            guard case let .coin(_, y, _) = item else { return nil }
            return y
        })

        #expect(firstLevelSprings == 0)
        #expect(!advancedSprings.isEmpty)
        #expect(advancedCoinHeights.count >= 4)

        for springX in advancedSprings {
            let segmentIndex = advancedLevel.segments.firstIndex {
                springX >= $0.startX && springX <= $0.endX
            }
            let index = try #require(segmentIndex)
            try #require(advancedLevel.segments.indices.contains(index + 1))
            let segment = advancedLevel.segments[index]
            let nextSegment = advancedLevel.segments[index + 1]
            #expect(nextSegment.startX - segment.endX > advancedDifficulty.gap)
        }
    }

    private func itemDescriptions(_ items: [LevelItem]) -> [String] {
        items.map { item in
            switch item {
            case let .spike(x): return "spike:\(x)"
            case let .coin(x, y, word): return "coin:\(x):\(y):\(word.id)"
            case let .gate(x): return "gate:\(x)"
            case let .spring(x): return "spring:\(x)"
            case let .challengeStar(x, y): return "star:\(x):\(y)"
            case let .enemy(x, kind): return "enemy:\(x):\(String(describing: kind))"
            case let .platform(x, y, width, kind):
                return "platform:\(x):\(y):\(width):\(String(describing: kind))"
            case let .wind(x, width): return "wind:\(x):\(width)"
            case let .shield(x, y): return "shield:\(x):\(y)"
            case let .checkpoint(x): return "checkpoint:\(x)"
            }
        }
    }
}
