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
    private let maxHold: TimeInterval = 0.18
    private let holdGravityFactor: CGFloat = 0.45
    private let playerSize: CGFloat = 46

    // MARK: World state
    private var words: [VocabWord] = Campaign.themes[0].words
    private var difficulty: Difficulty = .forLevel(0)
    private var skin: Skin = .forLevel(0)
    private var level = Level.generate(words: Campaign.themes[0].words, difficulty: .forLevel(0))
    private var scroll: CGFloat = 0
    private var playerY: CGFloat = 0   // height above the ground surface
    private var vy: CGFloat = 0
    private var onGround = true
    private var holding = false
    private var holdTime: TimeInterval = 0
    private var active = false
    private var lastUpdate: TimeInterval = 0
    private var quizWordQueue = QuizWordQueue()

    // MARK: Nodes
    private let sky = SKSpriteNode()
    private let celestialWrap = SKNode()
    private var farLayer = SKNode()
    private var nearLayer = SKNode()
    private let worldNode = SKNode()
    private let player = PlayerNode(size: 46)
    private var coins: [CoinNode] = []
    private var gates: [GateNode] = []
    private var spikes: [CGFloat] = []

    private final class CoinNode {
        let x: CGFloat
        let word: VocabWord
        let node: SKNode
        var collected = false
        init(x: CGFloat, word: VocabWord, node: SKNode) { self.x = x; self.word = word; self.node = node }
    }
    private final class GateNode {
        let x: CGFloat
        let node: SKNode
        var passed = false
        init(x: CGFloat, node: SKNode) { self.x = x; self.node = node }
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

        player.zPosition = 10
        addChild(player)

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
    }

    // MARK: Background

    private func buildBackground() {
        sky.texture = GradientTexture.vertical(size: CGSize(width: 4, height: 512),
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
        spikes.removeAll()

        for seg in level.segments {
            worldNode.addChild(makeGround(seg))
        }

        for item in level.items {
            switch item {
            case let .spike(x):
                spikes.append(x)
                worldNode.addChild(makeSpike(at: x))
            case let .coin(x, word):
                let n = makeCoin(at: x)
                worldNode.addChild(n)
                coins.append(CoinNode(x: x, word: word, node: n))
            case let .gate(x):
                let n = makeGate(at: x)
                worldNode.addChild(n)
                gates.append(GateNode(x: x, node: n))
            }
        }

        worldNode.addChild(makeFinish(at: level.finishX))
        layoutWorldHeights()
    }

    /// A ground segment: soil body with a grass strip and a darker lip on top.
    private func makeGround(_ seg: GroundSegment) -> SKNode {
        let w = seg.endX - seg.startX
        let node = SKNode()

        let soil = SKSpriteNode(color: skin.soil, size: CGSize(width: w, height: 2000))
        soil.anchorPoint = CGPoint(x: 0, y: 1)
        soil.position = .zero
        node.addChild(soil)

        let grass = SKSpriteNode(color: skin.grass, size: CGSize(width: w, height: 22))
        grass.anchorPoint = CGPoint(x: 0, y: 1)
        grass.position = .zero
        node.addChild(grass)

        let lip = SKSpriteNode(color: skin.grass.lighter(0.25), size: CGSize(width: w, height: 6))
        lip.anchorPoint = CGPoint(x: 0, y: 1)
        lip.position = .zero
        node.addChild(lip)

        node.position = CGPoint(x: seg.startX, y: 0)
        node.name = "ground"
        return node
    }

    private func makeSpike(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let base = skin.accent.darker(0.05)
        for dx in [-14.0, 14.0] as [CGFloat] {
            let s = SKShapeNode()
            let p = CGMutablePath()
            p.move(to: CGPoint(x: dx - 16, y: 0))
            p.addLine(to: CGPoint(x: dx, y: 46))
            p.addLine(to: CGPoint(x: dx + 16, y: 0))
            p.closeSubpath()
            s.path = p
            s.fillColor = SKColor(red: 0.86, green: 0.24, blue: 0.22, alpha: 1)
            s.strokeColor = base.darker(0.2)
            s.lineWidth = 2
            node.addChild(s)
        }
        node.name = "spike"
        node.position = CGPoint(x: x, y: 2)
        return node
    }

    private func makeCoin(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let ring = SKShapeNode(circleOfRadius: 21)
        ring.fillColor = skin.accent
        ring.strokeColor = skin.accent.darker(0.2)
        ring.lineWidth = 3
        node.addChild(ring)

        let face = SKShapeNode(circleOfRadius: 14)
        face.fillColor = SKColor(red: 1, green: 0.86, blue: 0.3, alpha: 1)
        face.strokeColor = .clear
        node.addChild(face)

        let shine = SKShapeNode(ellipseOf: CGSize(width: 7, height: 10))
        shine.fillColor = .white
        shine.strokeColor = .clear
        shine.alpha = 0.85
        shine.position = CGPoint(x: -5, y: 5)
        node.addChild(shine)

        node.name = "coin"
        node.position = CGPoint(x: x, y: 0)
        node.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.5), .scale(to: 1.0, duration: 0.5),
        ])))
        return node
    }

    private func makeGate(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let post = SKShapeNode(rectOf: CGSize(width: 12, height: 230), cornerRadius: 6)
        post.fillColor = SKColor(white: 1, alpha: 0.9)
        post.strokeColor = skin.accent
        post.lineWidth = 3
        post.position = CGPoint(x: 0, y: 115)
        node.addChild(post)

        let sign = SKShapeNode(circleOfRadius: 30)
        sign.fillColor = skin.accent
        sign.strokeColor = .white
        sign.lineWidth = 3
        sign.position = CGPoint(x: 0, y: 250)
        let q = SKLabelNode(text: "?")
        q.fontName = "AvenirNext-Bold"
        q.fontSize = 34
        q.fontColor = .white
        q.verticalAlignmentMode = .center
        sign.addChild(q)
        sign.run(.repeatForever(.sequence([
            .rotate(byAngle: 0.12, duration: 0.6), .rotate(byAngle: -0.12, duration: 0.6),
        ])))
        node.addChild(sign)

        node.name = "gate"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeFinish(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let pole = SKSpriteNode(color: SKColor(white: 0.95, alpha: 1),
                                size: CGSize(width: 8, height: 300))
        pole.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.addChild(pole)

        let flag = SKShapeNode()
        let p = CGMutablePath()
        p.move(to: CGPoint(x: 4, y: 300))
        p.addLine(to: CGPoint(x: 90, y: 268))
        p.addLine(to: CGPoint(x: 4, y: 236))
        p.closeSubpath()
        flag.path = p
        flag.fillColor = skin.accent
        flag.strokeColor = .clear
        node.addChild(flag)

        node.name = "finish"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    /// Ground and world objects live at y=0 in `worldNode`; anchor them to the
    /// current ground surface every layout so resizing stays correct.
    private func layoutWorldHeights() {
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        for c in coins { c.node.position.y = 96 }
        for g in gates { g.node.position.y = 0 }
    }

    // MARK: Loop

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard active else { return }
        let dt = min(lastUpdate == 0 ? 0 : currentTime - lastUpdate, 1.0 / 30)
        guard dt > 0 else { return }

        scroll += worldSpeed * CGFloat(dt)

        // Vertical integration with variable-height jump.
        let g: CGFloat
        if holding && holdTime < maxHold {
            holdTime += dt
            g = gravity * holdGravityFactor
        } else {
            g = gravity
        }
        vy -= g * CGFloat(dt)
        playerY += vy * CGFloat(dt)

        let worldX = scroll + playerScreenX
        let grounded = level.hasGround(at: worldX)

        if playerY <= 0 {
            if grounded && vy <= 0 {
                playerY = 0
                vy = 0
                onGround = true
            } else if !grounded {
                onGround = false // fall through the gap
            }
        } else {
            onGround = false
        }

        // Fell off the bottom of the world.
        if playerY < -(groundTopY + 120) {
            die(reason: "You fell into a gap!")
            return
        }

        checkSpikes(worldX: worldX)
        checkCoins(worldX: worldX)
        checkGates(worldX: worldX)

        if worldX >= level.finishX {
            active = false
            game?.finished()
            return
        }

        render()
        game?.updateDistance(Int(scroll / 100))
    }

    private func render() {
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        farLayer.position = CGPoint(x: -scroll * Scenery.farFactor, y: groundTopY)
        nearLayer.position = CGPoint(x: -scroll * Scenery.nearFactor, y: groundTopY)
        player.position = CGPoint(x: playerScreenX, y: groundTopY + playerSize / 2 + playerY)
        player.zRotation = onGround ? 0 : max(-0.5, -vy / 4000)
    }

    private func checkSpikes(worldX: CGFloat) {
        guard playerY < 40 else { return } // above the spike tips
        for sx in spikes where abs(sx - worldX) < 24 {
            die(reason: "Ouch — spikes!")
            return
        }
    }

    private func checkCoins(worldX: CGFloat) {
        for c in coins where !c.collected {
            if abs(c.x - worldX) < 34 && abs(playerY - 96) < 96 {
                c.collected = true
                c.node.run(.sequence([.group([.scale(to: 1.8, duration: 0.2),
                                              .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                quizWordQueue.collect(c.word)
                game?.collected(c.word)
            }
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
        player.flashDead()
        player.run(.sequence([.scale(to: 1.4, duration: 0.1), .scale(to: 0, duration: 0.2)]))
        game?.died(reason: reason)
    }

    // MARK: External control

    /// Configure the scene for a level and reset it, ready to `begin()`.
    func load(words: [VocabWord], difficulty: Difficulty, skin: Skin) {
        self.words = words
        self.difficulty = difficulty
        self.skin = skin
        rebuild()
    }

    /// Start (or resume from the level intro) running the level.
    func begin() {
        active = true
    }

    func resumeFromGate() {
        active = true
    }

    /// Rebuild the current level geometry and reset all player state, leaving
    /// the scene paused until `begin()` is called.
    private func rebuild() {
        level = Level.generate(words: words, difficulty: difficulty)
        scroll = 0
        playerY = 0
        vy = 0
        onGround = true
        holding = false
        holdTime = 0
        quizWordQueue.removeAll()
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

    // MARK: Input

    func jumpBegan() {
        guard active, onGround else { return }
        vy = jumpVelocity
        onGround = false
        holding = true
        holdTime = 0
        player.squashJump()
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
