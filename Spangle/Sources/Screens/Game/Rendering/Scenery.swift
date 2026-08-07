import SpriteKit

/// Builds the layered, custom-drawn backdrop for a level from its `Skin`.
/// Returns two parallax layers (far, near) plus a celestial disc. Everything is
/// vector-drawn and positioned relative to the ground line (y = 0 = surface).
enum Scenery {
    /// Parallax factors the scene scrolls each layer by.
    static let farFactor: CGFloat = 0.25
    static let nearFactor: CGFloat = 0.55

    struct Layers {
        let far: SKNode
        let near: SKNode
    }

    static func build(skin: Skin, finishX: CGFloat, screenWidth: CGFloat) -> Layers {
        let far = SKNode()
        let near = SKNode()
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: skin.decor.hashValue &+ 97))
        let farSpan = finishX * farFactor + screenWidth + 600
        let nearSpan = finishX * nearFactor + screenWidth + 600

        switch skin.decor {
        case .rainbowHills:
            rainbow(into: far, span: farSpan)
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            colourHills(into: near, span: nearSpan, rng: &rng)
        case .clouds:
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            clouds(into: far, span: farSpan, color: .white, rng: &rng)
            hillBands(into: near, span: nearSpan, skin: skin, rng: &rng, distant: false)
        case .rain:
            clouds(into: far, span: farSpan, color: skin.celestial.darker(0.15), rng: &rng)
            hillBands(into: near, span: nearSpan, skin: skin, rng: &rng, distant: false)
            rain(into: near, span: nearSpan, color: skin.accent, rng: &rng)
        case .savanna:
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            trees(into: near, span: nearSpan, skin: skin, rng: &rng, style: .acacia)
        case .hills:
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            hillBands(into: near, span: nearSpan, skin: skin, rng: &rng, distant: false)
            clouds(into: far, span: farSpan, color: .white, rng: &rng)
        case .town:
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            houses(into: near, span: nearSpan, skin: skin, rng: &rng)
        case .forest:
            hillBands(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            trees(into: near, span: nearSpan, skin: skin, rng: &rng, style: .pine)
        case .city:
            skyline(into: far, span: farSpan, skin: skin, rng: &rng, distant: true)
            skyline(into: near, span: nearSpan, skin: skin, rng: &rng, distant: false)
        case .mountains:
            mountains(into: far, span: farSpan, skin: skin, rng: &rng)
            stars(into: far, span: farSpan, rng: &rng)
            hillBands(into: near, span: nearSpan, skin: skin, rng: &rng, distant: false)
        }
        return Layers(far: far, near: near)
    }

    /// A glowing sun/moon disc that stays fixed on screen (does not scroll).
    static func celestial(skin: Skin) -> SKNode {
        let node = SKNode()
        let glow = SKShapeNode(circleOfRadius: 62)
        glow.fillColor = skin.celestial.withAlphaComponent(0.35)
        glow.strokeColor = .clear
        let disc = SKShapeNode(circleOfRadius: 42)
        disc.fillColor = skin.celestial
        disc.strokeColor = .clear
        node.addChild(glow)
        node.addChild(disc)
        return node
    }

    // MARK: - Decor primitives

    private static func hillBands(into node: SKNode, span: CGFloat, skin: Skin,
                                  rng: inout SeededGenerator, distant: Bool) {
        let color = distant ? skin.grass.lighter(0.35).darker(0.05) : skin.grass.darker(0.12)
        let baseY: CGFloat = distant ? 40 : 0
        let amp: CGFloat = distant ? 60 : 110
        let step: CGFloat = distant ? 320 : 240
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -200, y: -400))
        path.addLine(to: CGPoint(x: -200, y: baseY))
        var x: CGFloat = -200
        while x < span {
            let h = baseY + amp * CGFloat.random(in: 0.5...1, using: &rng)
            path.addQuadCurve(to: CGPoint(x: x + step, y: baseY),
                              control: CGPoint(x: x + step / 2, y: h))
            x += step
        }
        path.addLine(to: CGPoint(x: x, y: -400))
        path.closeSubpath()
        let hill = SKShapeNode(path: path)
        hill.fillColor = color
        hill.strokeColor = .clear
        node.addChild(hill)
    }

    private static func colourHills(into node: SKNode, span: CGFloat, rng: inout SeededGenerator) {
        let palette: [SKColor] = [
            SKColor(red: 0.95, green: 0.45, blue: 0.5, alpha: 1),
            SKColor(red: 0.98, green: 0.72, blue: 0.3, alpha: 1),
            SKColor(red: 0.55, green: 0.8, blue: 0.4, alpha: 1),
            SKColor(red: 0.4, green: 0.7, blue: 0.9, alpha: 1),
            SKColor(red: 0.7, green: 0.5, blue: 0.85, alpha: 1),
        ]
        var x: CGFloat = 0
        var i = 0
        while x < span {
            let r = CGFloat.random(in: 130...200, using: &rng)
            let hill = SKShapeNode(circleOfRadius: r)
            hill.fillColor = palette[i % palette.count]
            hill.strokeColor = .clear
            hill.position = CGPoint(x: x, y: -r * 0.55)
            node.addChild(hill)
            x += r * 1.2
            i += 1
        }
    }

    private static func clouds(into node: SKNode, span: CGFloat, color: SKColor,
                               rng: inout SeededGenerator) {
        var x = CGFloat.random(in: 100...500, using: &rng)
        while x < span {
            let cloud = SKNode()
            let scale = CGFloat.random(in: 0.7...1.4, using: &rng)
            for (dx, dy, r): (CGFloat, CGFloat, CGFloat) in
                [(-40, 0, 34), (0, 8, 44), (42, 0, 32), (0, -8, 40)] {
                let puff = SKShapeNode(circleOfRadius: r)
                puff.fillColor = color
                puff.strokeColor = .clear
                puff.position = CGPoint(x: dx, y: dy)
                cloud.addChild(puff)
            }
            cloud.setScale(scale)
            cloud.position = CGPoint(x: x, y: CGFloat.random(in: 260...440, using: &rng))
            cloud.alpha = 0.95
            node.addChild(cloud)
            x += CGFloat.random(in: 520...900, using: &rng)
        }
    }

    private static func rain(into node: SKNode, span: CGFloat, color: SKColor,
                             rng: inout SeededGenerator) {
        var x: CGFloat = 0
        while x < span {
            let drop = SKShapeNode()
            let p = CGMutablePath()
            let y = CGFloat.random(in: 60...420, using: &rng)
            p.move(to: CGPoint(x: x, y: y))
            p.addLine(to: CGPoint(x: x - 6, y: y - 18))
            drop.path = p
            drop.strokeColor = color.withAlphaComponent(0.5)
            drop.lineWidth = 2.5
            drop.lineCap = .round
            node.addChild(drop)
            x += CGFloat.random(in: 26...70, using: &rng)
        }
    }

    private enum TreeStyle { case pine, acacia }

    private static func trees(into node: SKNode, span: CGFloat, skin: Skin,
                              rng: inout SeededGenerator, style: TreeStyle) {
        var x: CGFloat = 60
        while x < span {
            let tree = SKNode()
            let h = CGFloat.random(in: 120...220, using: &rng)
            let trunk = SKShapeNode(rectOf: CGSize(width: h * 0.12, height: h * 0.4))
            trunk.fillColor = skin.soil.darker(0.1)
            trunk.strokeColor = .clear
            trunk.position = CGPoint(x: 0, y: h * 0.2)
            tree.addChild(trunk)

            let leaf = skin.grass.darker(style == .pine ? 0.25 : 0.05)
            if style == .pine {
                for (i, cy) in [0.35, 0.55, 0.75].enumerated() {
                    let tier = SKShapeNode()
                    let w = h * (0.55 - CGFloat(i) * 0.12)
                    let p = CGMutablePath()
                    p.move(to: CGPoint(x: -w / 2, y: h * cy))
                    p.addLine(to: CGPoint(x: w / 2, y: h * cy))
                    p.addLine(to: CGPoint(x: 0, y: h * cy + h * 0.28))
                    p.closeSubpath()
                    tier.path = p
                    tier.fillColor = leaf
                    tier.strokeColor = .clear
                    tree.addChild(tier)
                }
            } else { // acacia: flat umbrella canopy
                let canopy = SKShapeNode(ellipseOf: CGSize(width: h * 0.95, height: h * 0.4))
                canopy.fillColor = leaf
                canopy.strokeColor = .clear
                canopy.position = CGPoint(x: 0, y: h * 0.62)
                tree.addChild(canopy)
            }
            tree.position = CGPoint(x: x, y: 0)
            tree.setScale(CGFloat.random(in: 0.8...1.15, using: &rng))
            node.addChild(tree)
            x += CGFloat.random(in: 300...520, using: &rng)
        }
    }

    private static func houses(into node: SKNode, span: CGFloat, skin: Skin,
                               rng: inout SeededGenerator) {
        let walls: [SKColor] = [
            SKColor(red: 0.95, green: 0.85, blue: 0.7, alpha: 1),
            SKColor(red: 0.9, green: 0.7, blue: 0.6, alpha: 1),
            SKColor(red: 0.75, green: 0.85, blue: 0.9, alpha: 1),
        ]
        var x: CGFloat = 80
        var i = 0
        while x < span {
            let house = SKNode()
            let w = CGFloat.random(in: 120...180, using: &rng)
            let hgt = CGFloat.random(in: 110...170, using: &rng)
            let wall = SKShapeNode(rectOf: CGSize(width: w, height: hgt))
            wall.fillColor = walls[i % walls.count]
            wall.strokeColor = skin.soil.darker(0.1)
            wall.lineWidth = 2
            wall.position = CGPoint(x: 0, y: hgt / 2)
            house.addChild(wall)

            let roof = SKShapeNode()
            let p = CGMutablePath()
            p.move(to: CGPoint(x: -w / 2 - 8, y: hgt))
            p.addLine(to: CGPoint(x: w / 2 + 8, y: hgt))
            p.addLine(to: CGPoint(x: 0, y: hgt + w * 0.4))
            p.closeSubpath()
            roof.path = p
            roof.fillColor = skin.accent.darker(0.1)
            roof.strokeColor = .clear
            house.addChild(roof)

            for dx in [-w * 0.22, w * 0.22] {
                let win = SKShapeNode(rectOf: CGSize(width: w * 0.22, height: w * 0.22))
                win.fillColor = SKColor(red: 1, green: 0.9, blue: 0.5, alpha: 1)
                win.strokeColor = skin.soil.darker(0.1)
                win.lineWidth = 1.5
                win.position = CGPoint(x: dx, y: hgt * 0.55)
                house.addChild(win)
            }
            house.position = CGPoint(x: x, y: 0)
            node.addChild(house)
            x += w + CGFloat.random(in: 60...160, using: &rng)
            i += 1
        }
    }

    private static func skyline(into node: SKNode, span: CGFloat, skin: Skin,
                                rng: inout SeededGenerator, distant: Bool) {
        let color = distant ? skin.soil.lighter(0.25) : skin.soil.darker(0.05)
        var x: CGFloat = 0
        while x < span {
            let w = CGFloat.random(in: 90...150, using: &rng)
            let h = CGFloat.random(in: distant ? 160...300 : 220...420, using: &rng)
            let b = SKShapeNode(rectOf: CGSize(width: w, height: h))
            b.fillColor = color
            b.strokeColor = .clear
            b.position = CGPoint(x: x + w / 2, y: h / 2)
            node.addChild(b)
            if !distant {
                for row in stride(from: 40, to: h - 30, by: 46) {
                    for col in stride(from: -w / 2 + 22, to: w / 2 - 10, by: 34) {
                        let win = SKShapeNode(rectOf: CGSize(width: 12, height: 16))
                        win.fillColor = skin.accent.withAlphaComponent(
                            Bool.random(using: &rng) ? 0.9 : 0.25)
                        win.strokeColor = .clear
                        win.position = CGPoint(x: x + w / 2 + col, y: row)
                        node.addChild(win)
                    }
                }
            }
            x += w + CGFloat.random(in: 10...40, using: &rng)
        }
    }

    private static func mountains(into node: SKNode, span: CGFloat, skin: Skin,
                                  rng: inout SeededGenerator) {
        var x: CGFloat = -100
        while x < span {
            let w = CGFloat.random(in: 320...520, using: &rng)
            let h = CGFloat.random(in: 240...420, using: &rng)
            let m = SKShapeNode()
            let p = CGMutablePath()
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x + w / 2, y: h))
            p.addLine(to: CGPoint(x: x + w, y: 0))
            p.closeSubpath()
            m.path = p
            m.fillColor = skin.soil.lighter(0.15)
            m.strokeColor = .clear
            node.addChild(m)

            let cap = SKShapeNode()
            let cp = CGMutablePath()
            let cy = h * 0.7
            cp.move(to: CGPoint(x: x + w / 2 - w * 0.16, y: cy))
            cp.addLine(to: CGPoint(x: x + w / 2, y: h))
            cp.addLine(to: CGPoint(x: x + w / 2 + w * 0.16, y: cy))
            cp.closeSubpath()
            cap.path = cp
            cap.fillColor = .white
            cap.strokeColor = .clear
            node.addChild(cap)
            x += w * 0.7
        }
    }

    private static func stars(into node: SKNode, span: CGFloat, rng: inout SeededGenerator) {
        var x: CGFloat = 0
        while x < span {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3, using: &rng))
            star.fillColor = .white
            star.strokeColor = .clear
            star.position = CGPoint(x: x, y: CGFloat.random(in: 220...520, using: &rng))
            star.alpha = CGFloat.random(in: 0.5...1, using: &rng)
            node.addChild(star)
            x += CGFloat.random(in: 60...140, using: &rng)
        }
    }

    private static func rainbow(into node: SKNode, span: CGFloat) {
        let colors: [SKColor] = [.systemRed, .systemOrange, .systemYellow,
                                 .systemGreen, .systemBlue, .systemPurple]
        for (i, color) in colors.enumerated() {
            let arc = SKShapeNode()
            let r = 520 - CGFloat(i) * 26
            let p = CGMutablePath()
            p.addArc(center: CGPoint(x: span * 0.3, y: 0), radius: r,
                     startAngle: 0, endAngle: .pi, clockwise: false)
            arc.path = p
            arc.strokeColor = color.withAlphaComponent(0.6)
            arc.lineWidth = 26
            arc.fillColor = .clear
            node.addChild(arc)
        }
    }
}

/// Deterministic RNG so a level's scenery layout is stable across rebuilds.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E3779B97F4A7C15 }
    mutating func next() -> UInt64 {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
