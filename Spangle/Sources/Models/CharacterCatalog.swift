import Foundation

/// Ordered from approachable recolours to long-term prestige designs.
enum CharacterCatalog {
    static let all: [CharacterDesign] = [
        CharacterDesign(id: "sol", name: "Sol", tagline: "The golden original", cost: 0,
                        style: .sol, rarity: "Original"),
        CharacterDesign(id: "coral", name: "Coral Scout", tagline: "Ready for sunny trails", cost: 5,
                        style: .coral, rarity: "Common"),
        CharacterDesign(id: "forest", name: "Forest Sprite", tagline: "A little wild at heart", cost: 12,
                        style: .forest, rarity: "Common"),
        CharacterDesign(id: "midnight", name: "Midnight", tagline: "Silent, swift, unstoppable", cost: 24,
                        style: .midnight, rarity: "Rare"),
        CharacterDesign(id: "fiesta", name: "Fiesta Flame", tagline: "Every jump is a celebration", cost: 40,
                        style: .fiesta, rarity: "Rare"),
        CharacterDesign(id: "ocean", name: "Captain Azul", tagline: "Admiral of the open sky", cost: 65,
                        style: .ocean, rarity: "Rare"),
        CharacterDesign(id: "clockwork", name: "Professor Tick", tagline: "Precision-engineered brilliance", cost: 95,
                        style: .clockwork, rarity: "Epic"),
        CharacterDesign(id: "astronaut", name: "Nova", tagline: "One small jump, one giant word", cost: 140,
                        style: .astronaut, rarity: "Epic"),
        CharacterDesign(id: "knight", name: "Golden Errant", tagline: "A legend from La Mancha", cost: 210,
                        style: .knight, rarity: "Legendary"),
        CharacterDesign(id: "dragon", name: "Celestial Dragon", tagline: "Ancient starlight, awakened", cost: 350,
                        style: .dragon, rarity: "Mythic"),
        CharacterDesign(id: "aurora", name: "Aurora Royal", tagline: "Wears the northern lights", cost: 550,
                        style: .aurora, rarity: "Mythic"),
        CharacterDesign(id: "legend", name: "Prismatic Legend", tagline: "The ultimate Spangle", cost: 900,
                        style: .legend, rarity: "Prestige"),
    ]

    static let original = all[0]
}
