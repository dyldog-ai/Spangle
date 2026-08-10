import SpriteKit

/// A one-touch auto-runner. The world scrolls left at a constant speed while
/// the player stays at a fixed screen position; tap/click/space to jump.
/// Physics are integrated manually so behaviour is fully deterministic.
final class GameScene: SKScene {
    weak var game: GameViewModel?

    // MARK: Tuning
    private var worldSpeed: CGFloat { difficulty.worldSpeed }
    private let gravity: CGFloat = 2600
    private let jumpVelocity: CGFloat = 1050
    private let springVelocity: CGFloat = 1450
    private let maxHold: TimeInterval = 0.18
    private let holdGravityFactor: CGFloat = 0.45
    private let playerSize: CGFloat = 46

    // MARK: World state
    private var words: [VocabWord] = Campaign.themes[0].words
    private var difficulty: Difficulty = .forLevel(0)
    private var skin: Skin = .forLevel(0)
    private var level = Level.generate(words: Campaign.themes[0].words, difficulty: .forLevel(0))
    private var customLevel: Level?
    private var levelSeed: UInt64 = 0
    private var scroll: CGFloat = 0
    private var playerY: CGFloat = 0   // height above the ground surface
    private var vy: CGFloat = 0
    private var onGround = true
    private var holding = false
    private var holdTime: TimeInterval = 0
    private var active = false
    private var lastUpdate: TimeInterval = 0
    private var runTime: TimeInterval = 0
    private var invulnerabilityRemaining: TimeInterval = 0
    private var shielded = false
    private var quizWordQueue = QuizWordQueue()
    private var checkpointSnapshot: CheckpointSnapshot?

    // MARK: Nodes
    private let sky = SKSpriteNode()
    private let celestialWrap = SKNode()
    private var farLayer = SKNode()
    private var nearLayer = SKNode()
    private let worldNode = SKNode()
    private let playerShadow = SKShapeNode(ellipseOf: CGSize(width: 52, height: 13))
    private let player = PlayerNode(size: 46)
    private let vignette = SKSpriteNode()
    private var dustAccumulator: TimeInterval = 0
    private var coins: [CoinNode] = []
    private var gates: [GateNode] = []
    private var springs: [SpringNode] = []
    private var challengeStars: [ChallengeStarNode] = []
    private var enemies: [EnemyNode] = []
    private var platforms: [PlatformNode] = []
    private var winds: [WindNode] = []
    private var shields: [ShieldNode] = []
    private var checkpoints: [CheckpointNode] = []
    private var finishNode: SKNode?
    private var spikes: [CGFloat] = []

    private final class CoinNode {
        let x: CGFloat
        let y: CGFloat
        let word: VocabWord
        let node: SKNode
        var collected = false

        init(x: CGFloat, y: CGFloat, word: VocabWord, node: SKNode) {
            self.x = x
            self.y = y
            self.word = word
            self.node = node
        }
    }

    private final class GateNode {
        let x: CGFloat
        let node: SKNode
        var passed = false
        init(x: CGFloat, node: SKNode) { self.x = x; self.node = node }
    }

    private final class SpringNode {
        let x: CGFloat
        let node: SKNode
        var activated = false
        init(x: CGFloat, node: SKNode) { self.x = x; self.node = node }
    }

    private final class ChallengeStarNode {
        let x: CGFloat
        let y: CGFloat
        let node: SKNode
        var collected = false

        init(x: CGFloat, y: CGFloat, node: SKNode) {
            self.x = x
            self.y = y
            self.node = node
        }
    }

    private final class EnemyNode {
        let x: CGFloat
        let kind: EnemyKind
        let node: SKNode
        var defeated = false
        init(x: CGFloat, kind: EnemyKind, node: SKNode) {
            self.x = x
            self.kind = kind
            self.node = node
        }
    }

    private final class PlatformNode {
        let x: CGFloat
        let y: CGFloat
        let width: CGFloat
        let kind: PlatformKind
        let node: SKNode
        var crumbling = false
        var broken = false

        init(x: CGFloat, y: CGFloat, width: CGFloat, kind: PlatformKind, node: SKNode) {
            self.x = x
            self.y = y
            self.width = width
            self.kind = kind
            self.node = node
        }
    }

    private final class WindNode {
        let x: CGFloat
        let width: CGFloat
        let node: SKNode
        init(x: CGFloat, width: CGFloat, node: SKNode) {
            self.x = x
            self.width = width
            self.node = node
        }
    }

    private final class ShieldNode {
        let x: CGFloat
        let y: CGFloat
        let node: SKNode
        var collected = false
        init(x: CGFloat, y: CGFloat, node: SKNode) {
            self.x = x; self.y = y; self.node = node
        }
    }

    private final class CheckpointNode {
        let x: CGFloat
        let node: SKNode
        var activated = false
        init(x: CGFloat, node: SKNode) { self.x = x; self.node = node }
    }

    private struct CheckpointSnapshot {
        let scroll: CGFloat
        let coins: [Bool]
        let gates: [Bool]
        let springs: [Bool]
        let stars: [Bool]
        let enemies: [Bool]
        let platforms: [Bool]
        let shields: [Bool]
        let checkpoints: [Bool]
        let quizQueue: QuizWordQueue
        let shielded: Bool
    }

    private var playerScreenX: CGFloat { size.width * 0.28 }
    private var groundTopY: CGFloat { size.height * 0.26 }

    // MARK: Setup

    override func didMove(to view: SKView) {
        guard sky.parent == nil else { return } // build the hierarchy once
        sky.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sky.zPosition = -100
        addChild(sky)

        celestialWrap.zPosition = -70
        addChild(celestialWrap)

        farLayer.zPosition = -80
        nearLayer.zPosition = -60
        addChild(farLayer)
        addChild(nearLayer)

        worldNode.zPosition = 0
        addChild(worldNode)

        playerShadow.fillColor = SKColor(red: 0.18, green: 0.1, blue: 0.06, alpha: 0.24)
        playerShadow.strokeColor = .clear
        playerShadow.zPosition = 5
        addChild(playerShadow)

        player.zPosition = 10
        addChild(player)

        vignette.zPosition = 90
        vignette.isUserInteractionEnabled = false
        addChild(vignette)

        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutScreen()
    }

    /// Position full-screen and fixed elements for the current scene size.
    private func layoutScreen() {
        sky.size = size
        sky.position = CGPoint(x: size.width / 2, y: size.height / 2)
        celestialWrap.position = CGPoint(x: size.width * 0.78, y: size.height * 0.8)
        player.position = CGPoint(x: playerScreenX, y: groundTopY + playerSize / 2 + playerY)
        playerShadow.position = CGPoint(x: playerScreenX, y: groundTopY + 2)
        vignette.texture = GradientTexture.vignette(size: CGSize(width: 512, height: 288))
        vignette.size = size
        vignette.position = CGPoint(x: size.width / 2, y: size.height / 2)
    }

    // MARK: Background

    private func buildBackground() {
        sky.texture = GradientTexture.vertical(size: CGSize(width: 256, height: 512),
                                               top: skin.skyTop, bottom: skin.skyBottom)
        celestialWrap.removeAllChildren()
        celestialWrap.addChild(Scenery.celestial(skin: skin))

        let layers = Scenery.build(skin: skin, finishX: level.finishX, screenWidth: size.width)
        farLayer.removeAllChildren()
        nearLayer.removeAllChildren()
        for child in layers.far.children { child.removeFromParent(); farLayer.addChild(child) }
        for child in layers.near.children { child.removeFromParent(); nearLayer.addChild(child) }
    }

    // MARK: World

    private func buildWorld() {
        worldNode.removeAllChildren()
        coins.removeAll()
        gates.removeAll()
        springs.removeAll()
        challengeStars.removeAll()
        enemies.removeAll()
        platforms.removeAll()
        winds.removeAll()
        shields.removeAll()
        checkpoints.removeAll()
        finishNode = nil
        spikes.removeAll()

        for seg in level.segments {
            worldNode.addChild(makeGround(seg))
        }

        for item in level.items {
            switch item {
            case let .spike(x):
                spikes.append(x)
                worldNode.addChild(makeSpike(at: x))
            case let .coin(x, y, word):
                let node = makeCoin(at: x)
                worldNode.addChild(node)
                coins.append(CoinNode(x: x, y: y, word: word, node: node))
            case let .gate(x):
                let node = makeGate(at: x)
                worldNode.addChild(node)
                gates.append(GateNode(x: x, node: node))
            case let .spring(x):
                let node = makeSpring(at: x)
                worldNode.addChild(node)
                springs.append(SpringNode(x: x, node: node))
            case let .challengeStar(x, y):
                let node = makeChallengeStar(at: x)
                worldNode.addChild(node)
                challengeStars.append(ChallengeStarNode(x: x, y: y, node: node))
            case let .enemy(x, kind):
                let node = makeEnemy(at: x, kind: kind)
                worldNode.addChild(node)
                enemies.append(EnemyNode(x: x, kind: kind, node: node))
            case let .platform(x, y, width, kind):
                let node = makePlatform(at: x, width: width, kind: kind)
                worldNode.addChild(node)
                platforms.append(PlatformNode(x: x, y: y, width: width, kind: kind, node: node))
            case let .wind(x, width):
                let node = makeWind(at: x, width: width)
                worldNode.addChild(node)
                winds.append(WindNode(x: x, width: width, node: node))
            case let .shield(x, y):
                let node = makeShield(at: x)
                worldNode.addChild(node)
                shields.append(ShieldNode(x: x, y: y, node: node))
            case let .checkpoint(x):
                let node = makeCheckpoint(at: x)
                worldNode.addChild(node)
                checkpoints.append(CheckpointNode(x: x, node: node))
            }
        }

        let finish = makeFinish(at: level.finishX)
        worldNode.addChild(finish)
        finishNode = finish
        layoutWorldHeights()
    }

    /// A tactile cut-paper ground segment with a painted turf edge.
    private func makeGround(_ seg: GroundSegment) -> SKNode {
        let width = seg.endX - seg.startX
        let node = SKNode()
        let seed = UInt64(max(0, Int(seg.startX))) &+ levelSeed

        let soil = SKSpriteNode(texture: GradientTexture.paper(
            size: CGSize(width: 128, height: 128), color: skin.soil, seed: seed
        ))
        soil.size = CGSize(width: width, height: 2_000)
        soil.anchorPoint = CGPoint(x: 0, y: 1)
        node.addChild(soil)

        let earthShade = SKSpriteNode(color: skin.soil.darker(0.15),
                                      size: CGSize(width: width, height: 10))
        earthShade.anchorPoint = CGPoint(x: 0, y: 1)
        earthShade.position.y = -20
        earthShade.alpha = 0.28
        node.addChild(earthShade)

        let grass = SKSpriteNode(texture: GradientTexture.paper(
            size: CGSize(width: 96, height: 24), color: skin.grass, seed: seed ^ 0xABCDEF
        ))
        grass.size = CGSize(width: width, height: 24)
        grass.anchorPoint = CGPoint(x: 0, y: 1)
        node.addChild(grass)

        let highlight = SKSpriteNode(color: skin.grass.lighter(0.34),
                                     size: CGSize(width: width, height: 4))
        highlight.anchorPoint = CGPoint(x: 0, y: 1)
        highlight.position.y = 1
        node.addChild(highlight)

        var bladeX: CGFloat = 10
        while bladeX < width - 4 {
            let blade = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: bladeX, y: 0))
            path.addLine(to: CGPoint(x: bladeX + (Int(bladeX) % 2 == 0 ? 3 : -3), y: 8))
            blade.path = path
            blade.strokeColor = skin.grass.lighter(0.25).withAlphaComponent(0.72)
            blade.lineWidth = 1.5
            blade.lineCap = .round
            node.addChild(blade)
            bladeX += 34
        }

        node.position = CGPoint(x: seg.startX, y: 0)
        node.name = "ground"
        return node
    }

    private func makeSpike(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.29, green: 0.12, blue: 0.09, alpha: 1)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 66, height: 11))
        shadow.fillColor = ink.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        node.addChild(shadow)
        for (index, dx) in [-20.0, 0, 20.0].enumerated() {
            let thorn = SKShapeNode()
            let path = CGMutablePath()
            let height: CGFloat = index == 1 ? 50 : 39
            path.move(to: CGPoint(x: dx - 13, y: 1))
            path.addQuadCurve(to: CGPoint(x: dx, y: height),
                              control: CGPoint(x: dx - 4, y: height * 0.67))
            path.addQuadCurve(to: CGPoint(x: dx + 13, y: 1),
                              control: CGPoint(x: dx + 5, y: height * 0.64))
            path.closeSubpath()
            thorn.path = path
            thorn.fillColor = SKColor(red: 0.82, green: 0.2, blue: 0.15, alpha: 1)
            thorn.strokeColor = ink
            thorn.lineWidth = 2.2
            thorn.lineJoin = .round
            node.addChild(thorn)
            let glint = SKShapeNode(rectOf: CGSize(width: 2, height: height * 0.4), cornerRadius: 1)
            glint.fillColor = .white.withAlphaComponent(0.2)
            glint.strokeColor = .clear
            glint.position = CGPoint(x: dx - 4, y: height * 0.42)
            glint.zRotation = -0.13
            node.addChild(glint)
        }
        node.name = "spike"
        node.position = CGPoint(x: x, y: 2)
        return node
    }

    private func makeCoin(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.34, green: 0.18, blue: 0.05, alpha: 1)
        let shadow = SKShapeNode(circleOfRadius: 23)
        shadow.fillColor = ink.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2.5, y: -3)
        node.addChild(shadow)

        let ring = SKShapeNode(circleOfRadius: 22)
        ring.fillColor = SKColor(red: 0.95, green: 0.58, blue: 0.08, alpha: 1)
        ring.strokeColor = ink
        ring.lineWidth = 2.4
        node.addChild(ring)

        let face = SKShapeNode(circleOfRadius: 16)
        face.fillColor = SKColor(red: 1, green: 0.84, blue: 0.27, alpha: 1)
        face.strokeColor = .white.withAlphaComponent(0.48)
        face.lineWidth = 1.5
        node.addChild(face)

        let book = SKShapeNode()
        let bookPath = CGMutablePath()
        bookPath.move(to: CGPoint(x: -10, y: 7))
        bookPath.addQuadCurve(to: CGPoint(x: 0, y: 4), control: CGPoint(x: -5, y: 8))
        bookPath.addQuadCurve(to: CGPoint(x: 10, y: 7), control: CGPoint(x: 5, y: 8))
        bookPath.addLine(to: CGPoint(x: 10, y: -7))
        bookPath.addQuadCurve(to: CGPoint(x: 0, y: -5), control: CGPoint(x: 5, y: -6))
        bookPath.addQuadCurve(to: CGPoint(x: -10, y: -7), control: CGPoint(x: -5, y: -6))
        bookPath.closeSubpath()
        book.path = bookPath
        book.fillColor = SKColor(red: 1, green: 0.98, blue: 0.86, alpha: 1)
        book.strokeColor = ink
        book.lineWidth = 1.4
        node.addChild(book)
        let spine = SKShapeNode(rectOf: CGSize(width: 1.5, height: 12))
        spine.fillColor = ink.withAlphaComponent(0.6)
        spine.strokeColor = .clear
        node.addChild(spine)

        let shine = SKShapeNode(ellipseOf: CGSize(width: 5, height: 9))
        shine.fillColor = .white.withAlphaComponent(0.66)
        shine.strokeColor = .clear
        shine.position = CGPoint(x: -12, y: 10)
        shine.zRotation = -0.5
        node.addChild(shine)

        node.name = "coin"
        node.position = CGPoint(x: x, y: 0)
        node.run(.repeatForever(.sequence([
            .group([.scaleX(to: 0.18, duration: 0.34), .moveBy(x: 0, y: 3, duration: 0.34)]),
            .group([.scaleX(to: 1, duration: 0.34), .moveBy(x: 0, y: -3, duration: 0.34)]),
            .wait(forDuration: 0.2),
        ])))
        return node
    }

    private func makeSpring(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.26, green: 0.12, blue: 0.07, alpha: 1)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 82, height: 12))
        shadow.fillColor = ink.withAlphaComponent(0.22)
        shadow.strokeColor = .clear
        shadow.position.y = 2
        node.addChild(shadow)

        let base = SKShapeNode(rectOf: CGSize(width: 78, height: 18), cornerRadius: 9)
        base.fillColor = skin.accent.darker(0.12)
        base.strokeColor = ink
        base.lineWidth = 2.3
        base.position.y = 10
        node.addChild(base)
        let top = SKShapeNode(rectOf: CGSize(width: 66, height: 8), cornerRadius: 4)
        top.fillColor = skin.celestial
        top.strokeColor = .white.withAlphaComponent(0.55)
        top.lineWidth = 1.5
        top.position.y = 20
        node.addChild(top)

        for offset in [-21.0, 0, 21.0] as [CGFloat] {
            let chevron = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: offset - 5, y: 18))
            path.addLine(to: CGPoint(x: offset, y: 24))
            path.addLine(to: CGPoint(x: offset + 5, y: 18))
            chevron.path = path
            chevron.strokeColor = ink.withAlphaComponent(0.72)
            chevron.lineWidth = 2
            chevron.lineCap = .round
            chevron.lineJoin = .round
            node.addChild(chevron)
        }

        node.name = "spring"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeChallengeStar(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let star = SKShapeNode()
        let path = CGMutablePath()
        for pointIndex in 0..<10 {
            let angle = CGFloat(pointIndex) * .pi / 5 - .pi / 2
            let radius: CGFloat = pointIndex.isMultiple(of: 2) ? 27 : 12
            let point = CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
            pointIndex == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        star.path = path
        star.fillColor = SKColor(red: 1, green: 0.82, blue: 0.12, alpha: 1)
        star.strokeColor = .white
        star.lineWidth = 3
        node.addChild(star)
        node.run(.repeatForever(.group([
            .sequence([.scale(to: 1.16, duration: 0.55), .scale(to: 1, duration: 0.55)]),
            .rotate(byAngle: .pi * 2, duration: 3),
        ])))
        node.name = "challengeStar"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeEnemy(at x: CGFloat, kind: EnemyKind) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.2, green: 0.09, blue: 0.2, alpha: 1)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: 55, height: 11))
        shadow.fillColor = ink.withAlphaComponent(0.24)
        shadow.strokeColor = .clear
        shadow.position.y = 3
        node.addChild(shadow)

        let body: SKShapeNode
        switch kind {
        case .trickster:
            body = SKShapeNode(ellipseOf: CGSize(width: 58, height: 45))
            body.fillColor = SKColor(red: 0.49, green: 0.2, blue: 0.58, alpha: 1)
            let mask = SKShapeNode(ellipseOf: CGSize(width: 43, height: 19))
            mask.fillColor = SKColor(red: 0.17, green: 0.11, blue: 0.22, alpha: 1)
            mask.strokeColor = .clear
            mask.position.y = 30
            node.addChild(mask)
        case .hopper:
            body = SKShapeNode(circleOfRadius: 24)
            body.fillColor = SKColor(red: 0.88, green: 0.25, blue: 0.16, alpha: 1)
            for direction in [-1.0, 1.0] as [CGFloat] {
                let leg = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: direction * 13, y: 12))
                path.addLine(to: CGPoint(x: direction * 24, y: 2))
                path.addLine(to: CGPoint(x: direction * 31, y: 8))
                leg.path = path
                leg.strokeColor = ink
                leg.lineWidth = 4
                leg.lineCap = .round
                node.addChild(leg)
            }
        case .flyer:
            body = SKShapeNode(ellipseOf: CGSize(width: 54, height: 40))
            body.fillColor = SKColor(red: 0.12, green: 0.5, blue: 0.66, alpha: 1)
            shadow.isHidden = true
            for direction in [-1.0, 1.0] as [CGFloat] {
                let wing = SKShapeNode(ellipseOf: CGSize(width: 30, height: 15))
                wing.fillColor = SKColor(red: 0.65, green: 0.9, blue: 0.94, alpha: 1)
                wing.strokeColor = ink
                wing.lineWidth = 1.5
                wing.position = CGPoint(x: direction * 31, y: 28)
                wing.zRotation = direction * 0.2
                node.addChild(wing)
                wing.run(.repeatForever(.sequence([
                    .rotate(toAngle: direction * 0.45, duration: 0.1),
                    .rotate(toAngle: direction * -0.05, duration: 0.1),
                ])))
            }
        }
        body.strokeColor = ink
        body.lineWidth = 2.5
        body.position.y = 25
        node.addChild(body)

        for eyeX in [-10.0, 10.0] as [CGFloat] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: 8, height: 6))
            eye.fillColor = kind == .flyer ? .white : SKColor(red: 1, green: 0.83, blue: 0.24, alpha: 1)
            eye.strokeColor = .clear
            eye.position = CGPoint(x: eyeX, y: 31)
            node.addChild(eye)
        }
        if kind != .flyer {
            for footX in [-17.0, 17.0] as [CGFloat] {
                let foot = SKShapeNode(ellipseOf: CGSize(width: 19, height: 8))
                foot.fillColor = ink
                foot.strokeColor = .clear
                foot.position = CGPoint(x: footX, y: 6)
                node.addChild(foot)
            }
        }
        body.run(.repeatForever(.sequence([
            .moveBy(x: 0, y: 3, duration: 0.22), .moveBy(x: 0, y: -3, duration: 0.22),
        ])))
        node.name = "enemy"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makePlatform(at x: CGFloat, width: CGFloat, kind: PlatformKind) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.28, green: 0.14, blue: 0.08, alpha: 1)
        let shadow = SKShapeNode(ellipseOf: CGSize(width: width * 0.88, height: 13))
        shadow.fillColor = ink.withAlphaComponent(0.18)
        shadow.strokeColor = .clear
        shadow.position.y = -12
        node.addChild(shadow)
        let slab = SKShapeNode(rectOf: CGSize(width: width, height: 25), cornerRadius: 10)
        slab.fillColor = kind == .crumbling ? skin.soil.lighter(0.16) : skin.grass
        slab.strokeColor = ink
        slab.lineWidth = 2.4
        node.addChild(slab)
        let top = SKShapeNode(rectOf: CGSize(width: width - 10, height: 6), cornerRadius: 3)
        top.fillColor = kind == .crumbling ? skin.celestial : skin.grass.lighter(0.35)
        top.strokeColor = .clear
        top.position.y = 8
        node.addChild(top)
        if kind == .crumbling {
            for offset in [-0.25, 0.08, 0.32] as [CGFloat] {
                let crack = SKShapeNode()
                let path = CGMutablePath()
                path.move(to: CGPoint(x: width * offset, y: 8))
                path.addLine(to: CGPoint(x: width * offset - 5, y: 1))
                path.addLine(to: CGPoint(x: width * offset + 2, y: -7))
                crack.path = path
                crack.strokeColor = ink.withAlphaComponent(0.55)
                crack.lineWidth = 1.5
                node.addChild(crack)
            }
        }
        node.name = "platform"
        node.position.x = x
        return node
    }

    private func makeWind(at x: CGFloat, width: CGFloat) -> SKNode {
        let node = SKNode()
        let color = skin.celestial.lighter(0.25)
        for index in 0..<6 {
            let swirl = SKShapeNode()
            let path = CGMutablePath()
            let localX = -width / 2 + width * (CGFloat(index) + 0.5) / 6
            path.move(to: CGPoint(x: localX - 18, y: 20))
            path.addCurve(to: CGPoint(x: localX + 12, y: 150),
                          control1: CGPoint(x: localX + 34, y: 55),
                          control2: CGPoint(x: localX - 30, y: 105))
            swirl.path = path
            swirl.strokeColor = color.withAlphaComponent(0.4)
            swirl.lineWidth = 3
            swirl.lineCap = .round
            node.addChild(swirl)
            swirl.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: 55, duration: 0.85 + Double(index) * 0.04),
                .moveBy(x: 0, y: -55, duration: 0),
            ])))
        }
        node.name = "wind"
        node.position.x = x + width / 2
        return node
    }

    private func makeShield(at x: CGFloat) -> SKNode {
        let node = SKNode()
        for (radius, alpha) in [(31.0, 0.1), (27.0, 0.18)] {
            let glow = SKShapeNode(circleOfRadius: radius)
            glow.fillColor = SKColor(red: 0.22, green: 0.82, blue: 0.96, alpha: alpha)
            glow.strokeColor = .clear
            node.addChild(glow)
        }
        let orb = SKShapeNode(circleOfRadius: 23)
        orb.fillColor = SKColor(red: 0.18, green: 0.72, blue: 0.88, alpha: 0.72)
        orb.strokeColor = .white.withAlphaComponent(0.9)
        orb.lineWidth = 2.5
        node.addChild(orb)
        let crest = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 14))
        path.addLine(to: CGPoint(x: 11, y: 8))
        path.addLine(to: CGPoint(x: 8, y: -8))
        path.addQuadCurve(to: CGPoint(x: 0, y: -15), control: CGPoint(x: 5, y: -13))
        path.addQuadCurve(to: CGPoint(x: -8, y: -8), control: CGPoint(x: -5, y: -13))
        path.addLine(to: CGPoint(x: -11, y: 8))
        path.closeSubpath()
        crest.path = path
        crest.fillColor = .white.withAlphaComponent(0.84)
        crest.strokeColor = .clear
        node.addChild(crest)
        let glint = SKShapeNode(circleOfRadius: 3)
        glint.fillColor = .white
        glint.strokeColor = .clear
        glint.position = CGPoint(x: -10, y: 11)
        node.addChild(glint)
        node.run(.repeatForever(.group([
            .sequence([.scale(to: 1.1, duration: 0.52), .scale(to: 1, duration: 0.52)]),
            .sequence([.rotate(toAngle: 0.08, duration: 0.52),
                       .rotate(toAngle: -0.08, duration: 0.52)]),
        ])))
        node.name = "shield"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeCheckpoint(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.29, green: 0.14, blue: 0.08, alpha: 1)
        let base = SKShapeNode(ellipseOf: CGSize(width: 34, height: 11))
        base.fillColor = ink.withAlphaComponent(0.25)
        base.strokeColor = .clear
        node.addChild(base)
        let pole = SKShapeNode(rectOf: CGSize(width: 7, height: 150), cornerRadius: 3.5)
        pole.fillColor = SKColor(red: 0.96, green: 0.82, blue: 0.56, alpha: 1)
        pole.strokeColor = ink
        pole.lineWidth = 2
        pole.position.y = 75
        node.addChild(pole)
        let flag = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 4, y: 145))
        path.addQuadCurve(to: CGPoint(x: 64, y: 134), control: CGPoint(x: 34, y: 158))
        path.addLine(to: CGPoint(x: 52, y: 104))
        path.addQuadCurve(to: CGPoint(x: 4, y: 112), control: CGPoint(x: 30, y: 98))
        path.closeSubpath()
        flag.path = path
        flag.fillColor = skin.accent
        flag.strokeColor = ink
        flag.lineWidth = 2
        node.addChild(flag)
        let label = SKLabelNode(text: "PUNTO DE CONTROL")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 11
        label.fontColor = .white
        label.position = CGPoint(x: 23, y: 164)
        node.addChild(label)
        node.name = "checkpoint"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeGate(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.28, green: 0.13, blue: 0.08, alpha: 1)
        let foot = SKShapeNode(ellipseOf: CGSize(width: 36, height: 12))
        foot.fillColor = ink.withAlphaComponent(0.22)
        foot.strokeColor = .clear
        node.addChild(foot)
        let post = SKShapeNode(rectOf: CGSize(width: 15, height: 226), cornerRadius: 7)
        post.fillColor = SKColor(red: 0.96, green: 0.83, blue: 0.58, alpha: 1)
        post.strokeColor = ink
        post.lineWidth = 2.5
        post.position = CGPoint(x: 0, y: 113)
        node.addChild(post)

        for y in stride(from: CGFloat(28), through: 205, by: 28) {
            let tile = SKShapeNode(rectOf: CGSize(width: 8, height: 8), cornerRadius: 2)
            tile.fillColor = Int(y) / 28 % 2 == 0 ? skin.accent : skin.celestial
            tile.strokeColor = .clear
            tile.zRotation = .pi / 4
            tile.position.y = y
            node.addChild(tile)
        }

        let signShadow = SKShapeNode(circleOfRadius: 34)
        signShadow.fillColor = ink.withAlphaComponent(0.22)
        signShadow.strokeColor = .clear
        signShadow.position = CGPoint(x: 2, y: 245)
        node.addChild(signShadow)
        let sign = SKShapeNode(circleOfRadius: 31)
        sign.fillColor = skin.accent
        sign.strokeColor = ink
        sign.lineWidth = 2.8
        sign.position = CGPoint(x: 0, y: 250)
        let inner = SKShapeNode(circleOfRadius: 25)
        inner.fillColor = skin.accent.lighter(0.08)
        inner.strokeColor = .white.withAlphaComponent(0.55)
        inner.lineWidth = 1.5
        sign.addChild(inner)
        let questionMark = SKLabelNode(text: "?")
        questionMark.fontName = "AvenirNext-Heavy"
        questionMark.fontSize = 35
        questionMark.fontColor = .white
        questionMark.verticalAlignmentMode = .center
        questionMark.position.y = -1
        sign.addChild(questionMark)
        sign.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.08, duration: 0.55), .rotate(toAngle: -0.08, duration: 0.55),
        ])))
        node.addChild(sign)

        node.name = "gate"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeFinish(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ink = SKColor(red: 0.27, green: 0.13, blue: 0.07, alpha: 1)
        let base = SKShapeNode(ellipseOf: CGSize(width: 46, height: 13))
        base.fillColor = ink.withAlphaComponent(0.24)
        base.strokeColor = .clear
        node.addChild(base)
        let pole = SKShapeNode(rectOf: CGSize(width: 9, height: 300), cornerRadius: 4)
        pole.fillColor = SKColor(red: 0.97, green: 0.84, blue: 0.58, alpha: 1)
        pole.strokeColor = ink
        pole.lineWidth = 2.2
        pole.position.y = 150
        node.addChild(pole)

        let flag = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 5, y: 298))
        path.addQuadCurve(to: CGPoint(x: 104, y: 274), control: CGPoint(x: 54, y: 315))
        path.addLine(to: CGPoint(x: 86, y: 230))
        path.addQuadCurve(to: CGPoint(x: 5, y: 244), control: CGPoint(x: 47, y: 220))
        path.closeSubpath()
        flag.path = path
        flag.fillColor = skin.accent
        flag.strokeColor = ink
        flag.lineWidth = 2.5
        node.addChild(flag)
        let sun = SKShapeNode(circleOfRadius: 12)
        sun.fillColor = skin.celestial
        sun.strokeColor = .white.withAlphaComponent(0.7)
        sun.lineWidth = 1.5
        sun.position = CGPoint(x: 50, y: 272)
        node.addChild(sun)
        for angle in stride(from: CGFloat.zero, to: .pi * 2, by: .pi / 4) {
            let ray = SKShapeNode(rectOf: CGSize(width: 2, height: 9), cornerRadius: 1)
            ray.fillColor = skin.celestial
            ray.strokeColor = .clear
            ray.position = CGPoint(x: 50 + cos(angle) * 19, y: 272 + sin(angle) * 19)
            ray.zRotation = angle - .pi / 2
            node.addChild(ray)
        }

        node.name = "finish"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    /// Ground and world objects live at y=0 in `worldNode`; anchor them to the
    /// current ground surface every layout so resizing stays correct.
    private func layoutWorldHeights() {
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        let tallMarkerScale = min(1, max(0.68, (size.height - groundTopY - 72) / 310))
        for coin in coins { coin.node.position.y = coin.y }
        for gate in gates {
            gate.node.position.y = 0
            gate.node.setScale(tallMarkerScale)
        }
        finishNode?.setScale(tallMarkerScale)
        for spring in springs { spring.node.position.y = 0 }
        for star in challengeStars { star.node.position.y = star.y }
        for enemy in enemies { enemy.node.position.y = enemyHeight(enemy) }
        for platform in platforms { platform.node.position.y = platform.y - 12 }
        for wind in winds { wind.node.position.y = 0 }
        for shield in shields { shield.node.position.y = shield.y }
        for checkpoint in checkpoints { checkpoint.node.position.y = 0 }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard active else { return }
        let dt = min(lastUpdate == 0 ? 0 : currentTime - lastUpdate, 1.0 / 30)
        guard dt > 0 else { return }

        scroll += worldSpeed * CGFloat(dt)
        runTime += dt
        invulnerabilityRemaining = max(0, invulnerabilityRemaining - dt)

        let worldX = scroll + playerScreenX
        let previousPlayerY = playerY

        // Vertical integration with variable-height jump and visible updrafts.
        let g: CGFloat
        if holding && holdTime < maxHold {
            holdTime += dt
            g = gravity * holdGravityFactor
        } else {
            g = gravity
        }
        vy -= g * CGFloat(dt)
        if isInsideWind(worldX), !onGround {
            vy = min(900, vy + 1_900 * CGFloat(dt))
        }
        playerY += vy * CGFloat(dt)

        if let platform = landingPlatform(at: worldX, from: previousPlayerY, to: playerY) {
            playerY = platform.y
            vy = 0
            onGround = true
            beginCrumbling(platform)
        } else if playerY <= 0 {
            if level.hasGround(at: worldX), vy <= 0 {
                playerY = 0
                vy = 0
                onGround = true
            } else {
                onGround = false
            }
        } else {
            onGround = false
        }

        // Fell off the bottom of the world.
        if playerY < -(groundTopY + 120) {
            die(reason: "You fell into a gap!")
            return
        }

        checkShields(worldX: worldX)
        checkSpikes(worldX: worldX)
        guard active else { return }
        checkEnemies(worldX: worldX)
        guard active else { return }
        checkSprings(worldX: worldX)
        checkCoins(worldX: worldX)
        checkChallengeStars(worldX: worldX)
        checkCheckpoints(worldX: worldX)
        checkGates(worldX: worldX)
        guard active else { return }

        if worldX >= level.finishX {
            active = false
            game?.finished()
            return
        }

        render()
        dustAccumulator += dt
        if onGround, dustAccumulator >= 0.11, game?.settings.reducedMotion != true {
            dustAccumulator = 0
            spawnDust()
        }
        game?.updateRun(
            distanceMeters: Int(scroll / 100),
            progress: min(1, Double(worldX / level.finishX))
        )
    }

    private func render() {
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        farLayer.position = CGPoint(x: -scroll * Scenery.farFactor, y: groundTopY)
        nearLayer.position = CGPoint(x: -scroll * Scenery.nearFactor, y: groundTopY)
        player.position = CGPoint(x: playerScreenX, y: groundTopY + playerSize / 2 + playerY)
        player.zRotation = onGround ? 0 : max(-0.5, -vy / 4000)
        let shadowScale = max(0.42, 1 - max(0, playerY) / 380)
        playerShadow.position = CGPoint(x: playerScreenX,
                                        y: groundTopY + (onGround ? playerY : 0) + 2)
        playerShadow.xScale = shadowScale
        playerShadow.alpha = max(0.08, 0.3 - max(0, playerY) / 1_200)
        for enemy in enemies where !enemy.defeated {
            switch enemy.kind {
            case .trickster:
                enemy.node.position.x = enemy.x + sin(runTime * 3) * 42
                enemy.node.position.y = 0
            case .hopper:
                enemy.node.position.x = enemy.x + sin(runTime * 1.5) * 18
                enemy.node.position.y = abs(sin(runTime * 2.35)) * 92
            case .flyer:
                enemy.node.position.x = enemy.x + sin(runTime * 2.1) * 54
                enemy.node.position.y = 145 + sin(runTime * 2.8) * 34
            }
        }
    }

    private func enemyHeight(_ enemy: EnemyNode) -> CGFloat {
        switch enemy.kind {
        case .trickster: 0
        case .hopper: abs(sin(runTime * 2.35)) * 92
        case .flyer: 145 + sin(runTime * 2.8) * 34
        }
    }

    private func isInsideWind(_ worldX: CGFloat) -> Bool {
        winds.contains { worldX >= $0.x && worldX <= $0.x + $0.width }
    }

    private func landingPlatform(
        at worldX: CGFloat,
        from previousY: CGFloat,
        to currentY: CGFloat
    ) -> PlatformNode? {
        guard vy <= 0 else { return nil }
        return platforms
            .filter { platform in
                !platform.broken
                    && abs(platform.x - worldX) <= platform.width / 2 + playerSize * 0.22
                    && previousY >= platform.y - 2
                    && currentY <= platform.y + 8
            }
            .max { $0.y < $1.y }
    }

    private func beginCrumbling(_ platform: PlatformNode) {
        guard platform.kind == .crumbling, !platform.crumbling else { return }
        platform.crumbling = true
        platform.node.run(.sequence([
            .wait(forDuration: 0.2),
            .repeat(.sequence([
                .moveBy(x: -3, y: 0, duration: 0.035),
                .moveBy(x: 6, y: 0, duration: 0.035),
                .moveBy(x: -3, y: 0, duration: 0.035),
            ]), count: 3),
            .run { [weak platform] in platform?.broken = true },
            .group([
                .moveBy(x: 0, y: -100, duration: 0.38),
                .rotate(byAngle: 0.18, duration: 0.38),
                .fadeOut(withDuration: 0.3),
            ]),
            .removeFromParent(),
        ]))
    }

    private func checkShields(worldX: CGFloat) {
        for shield in shields where !shield.collected {
            guard abs(shield.x - worldX) < 38, abs(playerY - shield.y) < 78 else { continue }
            shield.collected = true
            shielded = true
            spawnBurst(
                at: CGPoint(x: shield.x - scroll, y: groundTopY + shield.y),
                colors: [.white, .cyan, skin.celestial],
                count: 13
            )
            shield.node.run(.sequence([
                .group([.scale(to: 2, duration: 0.2), .fadeOut(withDuration: 0.2)]),
                .removeFromParent(),
            ]))
            game?.shieldChanged(isActive: true)
        }
    }

    private func checkSpikes(worldX: CGFloat) {
        guard invulnerabilityRemaining <= 0, playerY < 40 else { return }
        for sx in spikes where abs(sx - worldX) < 24 {
            if consumeShield() { return }
            die(reason: "Ouch — spikes!")
            return
        }
    }

    private func checkEnemies(worldX: CGFloat) {
        guard invulnerabilityRemaining <= 0 else { return }
        for enemy in enemies where !enemy.defeated && abs(enemy.node.position.x - worldX) < 31 {
            let enemyY = enemy.node.position.y
            let overlapsVertically = playerY < enemyY + 48 && playerY + playerSize > enemyY + 4
            guard overlapsVertically else { continue }

            if vy < 0, playerY >= enemyY + 27 {
                enemy.defeated = true
                vy = 690
                onGround = false
                spawnBurst(
                    at: CGPoint(x: enemy.node.position.x - scroll,
                                y: groundTopY + enemyY + 26),
                    colors: [skin.celestial, skin.accent, .white],
                    count: 13
                )
                enemy.node.run(.sequence([
                    .group([.scaleY(to: 0.15, duration: 0.12),
                            .fadeOut(withDuration: 0.22)]),
                    .removeFromParent(),
                ]))
                game?.defeatedEnemy()
                continue
            }

            if consumeShield() { return }
            let reason: String
            switch enemy.kind {
            case .trickster: reason = "A masked trickster caught you!"
            case .hopper: reason = "A fire hopper bounced into you!"
            case .flyer: reason = "A sky swooper clipped you!"
            }
            die(reason: reason)
            return
        }
    }

    private func consumeShield() -> Bool {
        guard shielded else { return false }
        shielded = false
        invulnerabilityRemaining = 1.2
        game?.shieldChanged(isActive: false)
        player.run(.sequence([
            .fadeAlpha(to: 0.25, duration: 0.08),
            .fadeAlpha(to: 1, duration: 0.08),
            .fadeAlpha(to: 0.25, duration: 0.08),
            .fadeAlpha(to: 1, duration: 0.08),
        ]))
        return true
    }

    private func checkSprings(worldX: CGFloat) {
        for spring in springs where !spring.activated {
            guard worldX >= spring.x - 24, worldX <= spring.x + 30,
                  playerY < 34, vy <= 0 else { continue }
            spring.activated = true
            playerY = max(playerY, 1)
            vy = springVelocity
            onGround = false
            holding = false
            player.squashJump()
            spring.node.run(.sequence([
                .scaleY(to: 0.45, duration: 0.06),
                .scaleY(to: 1.25, duration: 0.08),
                .scaleY(to: 1, duration: 0.1),
            ]))
        }
    }

    private func checkCoins(worldX: CGFloat) {
        for coin in coins where !coin.collected {
            if abs(coin.x - worldX) < 36 && abs(playerY - coin.y) < 86 {
                coin.collected = true
                spawnBurst(
                    at: CGPoint(x: coin.x - scroll, y: groundTopY + coin.y),
                    colors: [skin.celestial, skin.accent, .white],
                    count: 10
                )
                coin.node.run(.sequence([.group([.scale(to: 1.8, duration: 0.2),
                                                  .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                quizWordQueue.collect(coin.word)
                game?.collected(coin.word)
            }
        }
    }

    private func checkChallengeStars(worldX: CGFloat) {
        for star in challengeStars where !star.collected {
            if abs(star.x - worldX) < 38 && abs(playerY - star.y) < 68 {
                star.collected = true
                spawnBurst(
                    at: CGPoint(x: star.x - scroll, y: groundTopY + star.y),
                    colors: [skin.celestial, .white, skin.accent],
                    count: 18
                )
                star.node.run(.sequence([
                    .group([
                        .scale(to: 2.2, duration: 0.24),
                        .fadeOut(withDuration: 0.24),
                        .rotate(byAngle: .pi, duration: 0.24),
                    ]),
                    .removeFromParent(),
                ]))
                game?.collectedChallengeStar()
            }
        }
    }

    private func checkCheckpoints(worldX: CGFloat) {
        for checkpoint in checkpoints where !checkpoint.activated && worldX >= checkpoint.x {
            checkpoint.activated = true
            checkpoint.node.alpha = 0.6
            spawnBurst(
                at: CGPoint(x: checkpoint.x - scroll, y: groundTopY + 128),
                colors: [skin.accent, skin.celestial, .white],
                count: 16
            )
            checkpoint.node.run(.sequence([
                .scale(to: 1.3, duration: 0.15), .scale(to: 1, duration: 0.15),
            ]))
            checkpointSnapshot = CheckpointSnapshot(
                scroll: scroll,
                coins: coins.map(\.collected),
                gates: gates.map(\.passed),
                springs: springs.map(\.activated),
                stars: challengeStars.map(\.collected),
                enemies: enemies.map(\.defeated),
                platforms: platforms.map(\.broken),
                shields: shields.map(\.collected),
                checkpoints: checkpoints.map(\.activated),
                quizQueue: quizWordQueue,
                shielded: shielded
            )
            game?.reachedCheckpoint()
        }
    }

    private func checkGates(worldX: CGFloat) {
        for gate in gates where !gate.passed {
            if worldX >= gate.x {
                gate.passed = true
                if let word = quizWordQueue.takeRandom() {
                    // Snap safely onto the ground so resuming never drops the
                    // player mid-air into the upcoming gap.
                    playerY = 0
                    vy = 0
                    onGround = true
                    active = false
                    game?.presentQuiz(for: word)
                }
            }
        }
    }

    private func die(reason: String) {
        guard active else { return }
        active = false
        spawnBurst(
            at: player.position,
            colors: [skin.accent, .white, SKColor(red: 0.9, green: 0.24, blue: 0.17, alpha: 1)],
            count: 14
        )
        player.flashDead()
        player.run(
            .sequence([.scale(to: 1.4, duration: 0.1), .scale(to: 0, duration: 0.2)]),
            withKey: "death"
        )
        game?.died(reason: reason)
    }

    // MARK: - Storybook effects

    private func spawnDust() {
        let dust = SKShapeNode(circleOfRadius: CGFloat.random(in: 2.5...5))
        dust.fillColor = skin.soil.lighter(0.32).withAlphaComponent(0.3)
        dust.strokeColor = .clear
        dust.position = CGPoint(x: playerScreenX - 20, y: groundTopY + 5)
        dust.zPosition = 7
        addChild(dust)
        dust.run(.sequence([
            .group([
                .moveBy(x: -24, y: CGFloat.random(in: 5...14), duration: 0.42),
                .scale(to: 1.8, duration: 0.42),
                .fadeOut(withDuration: 0.42),
            ]),
            .removeFromParent(),
        ]))
    }

    private func spawnJumpDust() {
        for index in 0..<5 {
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
            puff.fillColor = skin.soil.lighter(0.38).withAlphaComponent(0.38)
            puff.strokeColor = .clear
            puff.position = CGPoint(x: playerScreenX + CGFloat(index - 2) * 5,
                                    y: groundTopY + 5)
            puff.zPosition = 7
            addChild(puff)
            puff.run(.sequence([
                .group([
                    .moveBy(x: CGFloat(index - 2) * 8, y: CGFloat.random(in: 5...13), duration: 0.34),
                    .scale(to: 1.6, duration: 0.34),
                    .fadeOut(withDuration: 0.34),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    private func spawnBurst(at position: CGPoint, colors: [SKColor], count: Int) {
        guard game?.settings.reducedMotion != true else { return }
        for index in 0..<count {
            let particle: SKShapeNode
            if index.isMultiple(of: 3) {
                particle = SKShapeNode(rectOf: CGSize(width: 5, height: 5), cornerRadius: 1)
                particle.zRotation = .pi / 4
            } else {
                particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            }
            particle.fillColor = colors[index % colors.count]
            particle.strokeColor = .clear
            particle.position = position
            particle.zPosition = 30
            addChild(particle)

            let angle = CGFloat(index) / CGFloat(max(1, count)) * .pi * 2
                + CGFloat.random(in: -0.18...0.18)
            let distance = CGFloat.random(in: 30...72)
            particle.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * distance,
                            y: sin(angle) * distance + 10,
                            duration: 0.42),
                    .rotate(byAngle: CGFloat.random(in: -2...2), duration: 0.42),
                    .sequence([.wait(forDuration: 0.16), .fadeOut(withDuration: 0.26)]),
                ]),
                .removeFromParent(),
            ]))
        }
    }

    // MARK: External control

    /// Configure the scene for a level and reset it, ready to `begin()`.
    func load(words: [VocabWord], difficulty: Difficulty, skin: Skin, seed: UInt64 = 0) {
        self.words = words
        self.difficulty = difficulty
        self.skin = skin
        customLevel = nil
        levelSeed = seed
        rebuild()
    }

    #if DEVELOPER_FEATURES
    func loadCustom(level: Level, words: [VocabWord], difficulty: Difficulty, skin: Skin) {
        self.words = words
        self.difficulty = difficulty
        self.skin = skin
        customLevel = level
        levelSeed = 0
        rebuild()
    }
    #endif

    func setCharacterDesign(_ design: CharacterDesign) {
        player.apply(design: design)
        player.setAlive()
    }

    /// Start (or resume from the level intro) running the level.
    func begin() {
        active = true
    }

    func resumeFromGate() {
        lastUpdate = 0
        active = true
    }

    func pauseRun() {
        active = false
        holding = false
    }

    func resumeRun() {
        lastUpdate = 0
        active = true
    }

    /// Rebuild the current level geometry and reset all player state, leaving
    /// the scene paused until `begin()` is called.
    private func rebuild() {
        level = customLevel ?? Level.generate(words: words, difficulty: difficulty, seed: levelSeed)
        scroll = 0
        playerY = 0
        vy = 0
        onGround = true
        holding = false
        holdTime = 0
        quizWordQueue.removeAll()
        checkpointSnapshot = nil
        shielded = false
        invulnerabilityRemaining = 0
        runTime = 0
        dustAccumulator = 0
        lastUpdate = 0
        active = false
        player.setAlive()
        buildBackground()
        buildWorld()
        layoutScreen()
    }

    /// Retry the same level from the start.
    func restart() {
        rebuild()
    }

    /// Restores the exact collectible and quiz state captured at the latest checkpoint.
    @discardableResult
    func restartFromCheckpoint() -> Bool {
        guard let snapshot = checkpointSnapshot else { return false }
        buildBackground()
        buildWorld()
        scroll = snapshot.scroll
        playerY = 0
        vy = 0
        onGround = true
        holding = false
        holdTime = 0
        invulnerabilityRemaining = 0
        quizWordQueue = snapshot.quizQueue
        shielded = snapshot.shielded
        restore(snapshot.coins, to: coins, keyPath: \.collected)
        restore(snapshot.gates, to: gates, keyPath: \.passed)
        restore(snapshot.springs, to: springs, keyPath: \.activated)
        restore(snapshot.stars, to: challengeStars, keyPath: \.collected)
        restore(snapshot.enemies, to: enemies, keyPath: \.defeated)
        restore(snapshot.platforms, to: platforms, keyPath: \.broken)
        restore(snapshot.shields, to: shields, keyPath: \.collected)
        restore(snapshot.checkpoints, to: checkpoints, keyPath: \.activated)
        for coin in coins where coin.collected { coin.node.removeFromParent() }
        for gate in gates where gate.passed { gate.node.alpha = 0.45 }
        for star in challengeStars where star.collected { star.node.removeFromParent() }
        for enemy in enemies where enemy.defeated { enemy.node.removeFromParent() }
        for platform in platforms where platform.broken { platform.node.removeFromParent() }
        for shield in shields where shield.collected { shield.node.removeFromParent() }
        for checkpoint in checkpoints where checkpoint.activated { checkpoint.node.alpha = 0.45 }
        player.setAlive()
        layoutWorldHeights()
        render()
        lastUpdate = 0
        active = true
        game?.shieldChanged(isActive: shielded)
        return true
    }

    private func restore<Object: AnyObject>(
        _ values: [Bool],
        to objects: [Object],
        keyPath: ReferenceWritableKeyPath<Object, Bool>
    ) {
        for (index, value) in values.enumerated() where objects.indices.contains(index) {
            objects[index][keyPath: keyPath] = value
        }
    }

    // MARK: Input

    func jumpBegan() {
        guard active, onGround else { return }
        vy = jumpVelocity
        onGround = false
        holding = true
        holdTime = 0
        player.squashJump()
        if game?.settings.reducedMotion != true { spawnJumpDust() }
        game?.jumped()
    }

    func jumpEnded() {
        holding = false
        if vy > 0 { vy *= 0.4 } // cut the jump short for variable height
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { jumpBegan() }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { jumpEnded() }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { jumpEnded() }
    #elseif os(macOS)
    override func mouseDown(with event: NSEvent) { jumpBegan() }
    override func mouseUp(with event: NSEvent) { jumpEnded() }
    override func keyDown(with event: NSEvent) {
        if !event.isARepeat && (event.keyCode == 49 || event.keyCode == 126) { jumpBegan() } // space / up
    }
    override func keyUp(with event: NSEvent) {
        if event.keyCode == 49 || event.keyCode == 126 { jumpEnded() }
    }
    #endif
}
