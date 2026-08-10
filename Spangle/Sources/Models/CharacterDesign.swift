import Foundation

/// A purchasable visual identity for Sol. Gameplay dimensions never change.
struct CharacterDesign: Identifiable, Equatable {
    let id: String
    let name: String
    let tagline: String
    let cost: Int
    let style: Style
    let rarity: String

    enum Style: String, Codable, CaseIterable {
        case sol
        case coral
        case forest
        case midnight
        case fiesta
        case ocean
        case clockwork
        case astronaut
        case knight
        case dragon
        case aurora
        case legend
        case isaac
        case moonwalker
        case stardust
        case sleuth
        case plumber
        case speedster
    }
}
