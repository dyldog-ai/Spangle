#if DEVELOPER_FEATURES
import Foundation

struct EditableLevelObject: Identifiable, Codable, Equatable {
    var id = UUID()
    var kind: Kind
    var x: Double
    var y: Double
    var width: Double
    var spanish: String
    var english: String

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case coin
        case spike
        case gate
        case spring
        case star
        case trickster
        case hopper
        case flyer
        case solidPlatform
        case crumblingPlatform
        case wind
        case shield
        case checkpoint
        case gap

        var id: String { rawValue }

        var title: String {
            switch self {
            case .coin: "Word coin"
            case .spike: "Spikes"
            case .gate: "Quiz gate"
            case .spring: "Spring"
            case .star: "Challenge star"
            case .trickster: "Trickster"
            case .hopper: "Fire hopper"
            case .flyer: "Sky swooper"
            case .solidPlatform: "Platform"
            case .crumblingPlatform: "Crumbling platform"
            case .wind: "Updraft"
            case .shield: "Shield"
            case .checkpoint: "Checkpoint"
            case .gap: "Ground gap"
            }
        }

        var symbol: String {
            switch self {
            case .coin: "book.circle.fill"
            case .spike: "triangle.fill"
            case .gate: "questionmark.circle.fill"
            case .spring: "arrow.up.square.fill"
            case .star: "star.fill"
            case .trickster: "theatermasks.fill"
            case .hopper: "flame.fill"
            case .flyer: "bird.fill"
            case .solidPlatform: "rectangle.fill"
            case .crumblingPlatform: "rectangle.split.3x1.fill"
            case .wind: "wind"
            case .shield: "shield.fill"
            case .checkpoint: "flag.fill"
            case .gap: "rectangle.dashed"
            }
        }

        var defaultY: Double {
            switch self {
            case .coin: 100
            case .star: 180
            case .flyer: 160
            case .solidPlatform, .crumblingPlatform: 100
            case .wind: 0
            case .shield: 110
            default: 0
            }
        }

        var defaultWidth: Double {
            switch self {
            case .solidPlatform, .crumblingPlatform: 140
            case .wind: 320
            case .gap: 220
            default: 60
            }
        }
    }

    static func make(kind: Kind, x: Double) -> EditableLevelObject {
        EditableLevelObject(
            kind: kind,
            x: x,
            y: kind.defaultY,
            width: kind.defaultWidth,
            spanish: kind == .coin ? "hola" : "",
            english: kind == .coin ? "hello" : ""
        )
    }
}
#endif
