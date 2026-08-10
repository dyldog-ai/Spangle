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
        CharacterDesign(id: "isaac", name: "Basement Isaac", tagline: "Tears turn every trial around", cost: 180,
                        style: .isaac, rarity: "Cult Classic"),
        CharacterDesign(id: "moonwalker", name: "Moonwalk Maestro", tagline: "A smooth criminal of gravity", cost: 260,
                        style: .moonwalker, rarity: "Iconic"),
        CharacterDesign(id: "stardust", name: "Stardust Rebel", tagline: "A cosmic flash from another stage", cost: 320,
                        style: .stardust, rarity: "Iconic"),
        CharacterDesign(id: "sleuth", name: "Baker Street Sleuth", tagline: "The game is afoot", cost: 390,
                        style: .sleuth, rarity: "Legendary"),
        CharacterDesign(id: "plumber", name: "Pixel Plumber", tagline: "Pipes, jumps, and power-ups", cost: 480,
                        style: .plumber, rarity: "Iconic"),
        CharacterDesign(id: "speedster", name: "Cobalt Speedster", tagline: "Gotta learn fast", cost: 650,
                        style: .speedster, rarity: "Mythic"),
    ]

    static let original = all[0]
}
