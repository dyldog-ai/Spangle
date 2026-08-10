#if DEVELOPER_FEATURES
import CoreGraphics
import Foundation

struct CustomLevelDefinition: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var emoji: String
    var finishX: Double
    var difficultyIndex: Int
    var objects: [EditableLevelObject]

    static var starter: CustomLevelDefinition {
        var firstCoin = EditableLevelObject.make(kind: .coin, x: 900)
        firstCoin.spanish = "hola"
        firstCoin.english = "hello"
        var secondCoin = EditableLevelObject.make(kind: .coin, x: 2_150)
        secondCoin.spanish = "salta"
        secondCoin.english = "jump"
        var thirdCoin = EditableLevelObject.make(kind: .coin, x: 3_250)
        thirdCoin.spanish = "estrella"
        thirdCoin.english = "star"
        var fourthCoin = EditableLevelObject.make(kind: .coin, x: 4_050)
        fourthCoin.spanish = "meta"
        fourthCoin.english = "finish"
        return CustomLevelDefinition(
            title: "My Level",
            emoji: "🛠️",
            finishX: 4_800,
            difficultyIndex: 3,
            objects: [
                firstCoin,
                .make(kind: .spike, x: 1_250),
                .make(kind: .solidPlatform, x: 1_650),
                .make(kind: .star, x: 1_650),
                .make(kind: .gap, x: 2_150),
                .make(kind: .spring, x: 1_950),
                secondCoin,
                .make(kind: .gate, x: 2_700),
                .make(kind: .hopper, x: 3_200),
                thirdCoin,
                .make(kind: .checkpoint, x: 3_600),
                fourthCoin,
            ]
        )
    }

    var words: [VocabWord] {
        let values = objects.compactMap { object -> VocabWord? in
            guard object.kind == .coin,
                  !object.spanish.trimmingCharacters(in: .whitespaces).isEmpty,
                  !object.english.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
            return VocabWord(spanish: object.spanish, english: object.english)
        }
        var seen = Set<String>()
        return values.filter { seen.insert($0.id).inserted }
    }

    static func parseVocabulary(_ text: String) -> [VocabWord]? {
        let lines = text.split(whereSeparator: \.isNewline)
        guard !lines.isEmpty else { return nil }
        var parsed: [VocabWord] = []
        for line in lines {
            let parts = line.split(separator: "=", maxSplits: 1).map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty else { return nil }
            parsed.append(VocabWord(spanish: parts[0], english: parts[1]))
        }
        return parsed
    }

    mutating func replaceVocabulary(with newWords: [VocabWord]) {
        let coinIndices = objects.indices
            .filter { objects[$0].kind == .coin }
            .sorted { objects[$0].x < objects[$1].x }
        var retainedCoinIDs = Set<UUID>()
        var nextX = max(800, coinIndices.compactMap { objects[$0].x }.max().map { $0 + 500 } ?? 800)

        for (wordIndex, word) in newWords.enumerated() {
            if wordIndex < coinIndices.count {
                let objectIndex = coinIndices[wordIndex]
                objects[objectIndex].spanish = word.spanish
                objects[objectIndex].english = word.english
                retainedCoinIDs.insert(objects[objectIndex].id)
            } else {
                if nextX >= finishX - 100 { finishX = nextX + 500 }
                var coin = EditableLevelObject.make(kind: .coin, x: nextX)
                coin.spanish = word.spanish
                coin.english = word.english
                retainedCoinIDs.insert(coin.id)
                objects.append(coin)
                nextX += 500
            }
        }
        objects.removeAll { $0.kind == .coin && !retainedCoinIDs.contains($0.id) }
    }

    var vocabularyText: String {
        words.map { "\($0.spanish) = \($0.english)" }.joined(separator: "\n")
    }

    var validationMessage: String? {
        if title.trimmingCharacters(in: .whitespaces).isEmpty { return "Add a level title." }
        if words.count < 4 { return "Add at least four word coins with unique vocabulary." }
        if finishX < 1_500 { return "The finish must be at least 1,500 points away." }
        if objects.contains(where: { $0.x < 500 || $0.x >= finishX - 100 }) {
            return "Keep objects between 500 and 100 points before the finish."
        }
        return nil
    }

    func makeLevel() -> Level {
        let finish = CGFloat(finishX)
        let gaps = objects
            .filter { $0.kind == .gap }
            .sorted { $0.x < $1.x }
        var segments: [GroundSegment] = []
        var cursor: CGFloat = -400
        for gap in gaps {
            let halfWidth = CGFloat(max(80, gap.width)) / 2
            let start = CGFloat(gap.x) - halfWidth
            let end = CGFloat(gap.x) + halfWidth
            if start > cursor { segments.append(GroundSegment(startX: cursor, endX: start)) }
            cursor = max(cursor, end)
        }
        if cursor < finish + 400 {
            segments.append(GroundSegment(startX: cursor, endX: finish + 400))
        }

        let items = objects.compactMap { object -> LevelItem? in
            let x = CGFloat(object.x)
            let y = CGFloat(max(0, object.y))
            switch object.kind {
            case .coin:
                let word = VocabWord(spanish: object.spanish, english: object.english)
                return .coin(x: x, y: y, word: word)
            case .spike: return .spike(x: x)
            case .gate: return .gate(x: x)
            case .spring: return .spring(x: x)
            case .star: return .challengeStar(x: x, y: y)
            case .trickster: return .enemy(x: x, kind: .trickster)
            case .hopper: return .enemy(x: x, kind: .hopper)
            case .flyer: return .enemy(x: x, kind: .flyer)
            case .solidPlatform:
                return .platform(x: x, y: y, width: CGFloat(max(100, object.width)), kind: .solid)
            case .crumblingPlatform:
                return .platform(x: x, y: y, width: CGFloat(max(100, object.width)), kind: .crumbling)
            case .wind: return .wind(x: x, width: CGFloat(max(120, object.width)))
            case .shield: return .shield(x: x, y: y)
            case .checkpoint: return .checkpoint(x: x)
            case .gap: return nil
            }
        }
        return Level(segments: segments, items: items, finishX: finish)
    }
}
#endif
