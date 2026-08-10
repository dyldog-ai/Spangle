import CoreGraphics
import Testing
@testable import Spangle

struct LevelTests {
    @Test
    func highSpeedGatesLeaveEnoughRunwayWithoutPausingScroll() throws {
        let difficulty = Difficulty.forLevel(20)
        let words = (0..<8).map {
            VocabWord(spanish: "palabra \($0)", english: "word \($0)")
        }
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
}
