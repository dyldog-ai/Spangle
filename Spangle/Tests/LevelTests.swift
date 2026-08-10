import CoreGraphics
import Testing
@testable import Spangle

struct LevelTests {
    private let words = (0..<8).map {
        VocabWord(spanish: "palabra \($0)", english: "word \($0)")
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
}
