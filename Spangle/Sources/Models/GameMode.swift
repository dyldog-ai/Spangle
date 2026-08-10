import Foundation

enum GameMode: Equatable {
    case campaign
    case imported
    case daily(seed: UInt64)
    case marathon
    case review

    var recordsCampaignProgress: Bool { self == .campaign }
}
