import SpriteKit

/// The visual identity of a level: a colour palette plus a parallax decor
/// style. Each theme maps to one skin, giving every level its own look while
/// the drawing code stays shared and data-driven.
struct Skin {
    let skyTop: SKColor
    let skyBottom: SKColor
    let grass: SKColor       // top strip of the ground
    let soil: SKColor        // body of the ground below the grass
    let accent: SKColor      // coins / gate / flourishes
    let celestial: SKColor   // sun or moon disc
    let decor: Decor

    enum Decor {
        case rainbowHills
        case clouds
        case rain
        case savanna
        case hills
        case town
        case forest
        case city
        case mountains
    }

    /// Skin for a given level index, matched to the campaign theme order.
    static func forLevel(_ i: Int) -> Skin {
        skins[min(i, skins.count - 1)]
    }

    private static func c(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> SKColor {
        SKColor(red: r / 255, green: g / 255, blue: b / 255, alpha: 1)
    }

    // Ordered to match Campaign.themes.
    private static let skins: [Skin] = [
        // 1 · Los Colores — playful pastel rainbow
        Skin(skyTop: c(255, 214, 236), skyBottom: c(214, 224, 255), grass: c(120, 214, 120),
             soil: c(150, 100, 70), accent: c(233, 64, 160), celestial: c(255, 241, 120),
             decor: .rainbowHills),
        // 2 · Los Números — clean bright day
        Skin(skyTop: c(120, 190, 255), skyBottom: c(210, 238, 255), grass: c(96, 200, 150),
             soil: c(90, 110, 130), accent: c(52, 120, 246), celestial: c(255, 244, 150),
             decor: .clouds),
        // 3 · Los Animales — warm savanna
        Skin(skyTop: c(255, 178, 84), skyBottom: c(255, 226, 150), grass: c(196, 190, 96),
             soil: c(150, 110, 60), accent: c(230, 120, 40), celestial: c(255, 236, 150),
             decor: .savanna),
        // 4 · La Comida — picnic afternoon
        Skin(skyTop: c(255, 196, 150), skyBottom: c(255, 236, 200), grass: c(122, 200, 96),
             soil: c(150, 100, 70), accent: c(224, 66, 66), celestial: c(255, 240, 160),
             decor: .hills),
        // 5 · La Familia — cosy town
        Skin(skyTop: c(150, 196, 255), skyBottom: c(214, 232, 255), grass: c(120, 206, 120),
             soil: c(140, 96, 66), accent: c(150, 80, 220), celestial: c(255, 244, 150),
             decor: .town),
        // 6 · La Casa — suburban day
        Skin(skyTop: c(120, 200, 240), skyBottom: c(210, 240, 250), grass: c(120, 206, 120),
             soil: c(140, 96, 66), accent: c(40, 170, 170), celestial: c(255, 244, 150),
             decor: .town),
        // 7 · El Cuerpo — fresh cyan sky
        Skin(skyTop: c(110, 224, 224), skyBottom: c(214, 248, 244), grass: c(120, 210, 130),
             soil: c(140, 100, 70), accent: c(236, 90, 140), celestial: c(255, 244, 160),
             decor: .clouds),
        // 8 · La Naturaleza — deep forest
        Skin(skyTop: c(120, 200, 200), skyBottom: c(214, 240, 220), grass: c(74, 168, 96),
             soil: c(96, 72, 50), accent: c(60, 160, 80), celestial: c(255, 240, 170),
             decor: .forest),
        // 9 · El Tiempo — overcast & rain
        Skin(skyTop: c(120, 134, 150), skyBottom: c(186, 198, 210), grass: c(110, 168, 120),
             soil: c(96, 96, 104), accent: c(90, 120, 200), celestial: c(224, 228, 236),
             decor: .rain),
        // 10 · El Viaje — city at dusk
        Skin(skyTop: c(70, 80, 140), skyBottom: c(255, 168, 120), grass: c(120, 130, 130),
             soil: c(80, 82, 90), accent: c(255, 206, 70), celestial: c(255, 210, 130),
             decor: .city),
        // 11 · Las Emociones — sunset
        Skin(skyTop: c(255, 130, 110), skyBottom: c(150, 96, 200), grass: c(120, 190, 120),
             soil: c(120, 84, 64), accent: c(255, 200, 70), celestial: c(255, 220, 150),
             decor: .hills),
        // 12 · Los Verbos — night mountains
        Skin(skyTop: c(24, 30, 70), skyBottom: c(80, 70, 140), grass: c(60, 120, 80),
             soil: c(60, 54, 72), accent: c(120, 220, 255), celestial: c(238, 240, 255),
             decor: .mountains),
    ]
}

extension SKColor {
    /// Blend towards white.
    func lighter(_ t: CGFloat) -> SKColor { blended(white: true, t) }
    /// Blend towards black.
    func darker(_ t: CGFloat) -> SKColor { blended(white: false, t) }

    private func blended(white: Bool, _ t: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        #if os(macOS)
        let rgb = usingColorSpace(.sRGB) ?? self
        rgb.getRed(&r, green: &g, blue: &b, alpha: &a)
        #else
        getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif
        let target: CGFloat = white ? 1 : 0
        return SKColor(red: r + (target - r) * t, green: g + (target - g) * t,
                       blue: b + (target - b) * t, alpha: a)
    }
}
