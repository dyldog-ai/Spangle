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
    private let player = PlayerNode(size: 46)
    private var coins: [CoinNode] = []
    private var gates: [GateNode] = []
    private var springs: [SpringNode] = []
    private var challengeStars: [ChallengeStarNode] = []
    private var enemies: [EnemyNode] = []
    private var shields: [ShieldNode] = []
    private var checkpoints: [CheckpointNode] = []
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
        let node: SKNode
        init(x: CGFloat, node: SKNode) { self.x = x; self.node = node }
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
        springs.removeAll()
        challengeStars.removeAll()
        enemies.removeAll()
        shields.removeAll()
        checkpoints.removeAll()
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
            case let .enemy(x):
                let node = makeEnemy(at: x)
                worldNode.addChild(node)
                enemies.append(EnemyNode(x: x, node: node))
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

    private func makeSpring(at x: CGFloat) -> SKNode {
        let node = SKNode()

        let base = SKShapeNode(rectOf: CGSize(width: 76, height: 16), cornerRadius: 7)
        base.fillColor = skin.accent.darker(0.18)
        base.strokeColor = .white
        base.lineWidth = 2
        base.position.y = 8
        node.addChild(base)

        for offset in [-22.0, 0, 22.0] as [CGFloat] {
            let arrow = SKLabelNode(text: "▲")
            arrow.fontName = "AvenirNext-Bold"
            arrow.fontSize = 19
            arrow.fontColor = .white
            arrow.verticalAlignmentMode = .center
            arrow.position = CGPoint(x: offset, y: 18)
            node.addChild(arrow)
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

    private func makeEnemy(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let body = SKShapeNode(ellipseOf: CGSize(width: 54, height: 42))
        body.fillColor = SKColor(red: 0.55, green: 0.22, blue: 0.68, alpha: 1)
        body.strokeColor = .white
        body.lineWidth = 2
        body.position.y = 24
        node.addChild(body)
        for eyeX in [-11.0, 11.0] as [CGFloat] {
            let eye = SKShapeNode(circleOfRadius: 5)
            eye.fillColor = .white
            eye.strokeColor = .clear
            eye.position = CGPoint(x: eyeX, y: 30)
            node.addChild(eye)
        }
        node.name = "enemy"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeShield(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let orb = SKShapeNode(circleOfRadius: 25)
        orb.fillColor = SKColor(red: 0.2, green: 0.8, blue: 1, alpha: 0.65)
        orb.strokeColor = .white
        orb.lineWidth = 3
        let label = SKLabelNode(text: "◆")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 24
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        node.addChild(orb)
        node.addChild(label)
        node.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.55), .scale(to: 1, duration: 0.55),
        ])))
        node.name = "shield"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeCheckpoint(at x: CGFloat) -> SKNode {
        let node = SKNode()
        let pole = SKSpriteNode(color: .white, size: CGSize(width: 6, height: 150))
        pole.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.addChild(pole)
        let flag = SKLabelNode(text: "⚑")
        flag.fontSize = 48
        flag.verticalAlignmentMode = .center
        flag.position = CGPoint(x: 19, y: 133)
        node.addChild(flag)
        let label = SKLabelNode(text: "CHECKPOINT")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 13
        label.fontColor = .white
        label.position = CGPoint(x: 0, y: 165)
        node.addChild(label)
        node.name = "checkpoint"
        node.position = CGPoint(x: x, y: 0)
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
        for coin in coins { coin.node.position.y = coin.y }
        for gate in gates { gate.node.position.y = 0 }
        for spring in springs { spring.node.position.y = 0 }
        for star in challengeStars { star.node.position.y = star.y }
        for enemy in enemies { enemy.node.position.y = 0 }
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
        for enemy in enemies {
            enemy.node.position.x = enemy.x + sin(runTime * 3) * 42
        }
    }

    private func checkShields(worldX: CGFloat) {
        for shield in shields where !shield.collected {
            guard abs(shield.x - worldX) < 38, abs(playerY - shield.y) < 78 else { continue }
            shield.collected = true
            shielded = true
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
        guard invulnerabilityRemaining <= 0, playerY < 46 else { return }
        for enemy in enemies where abs(enemy.node.position.x - worldX) < 30 {
            if consumeShield() { return }
            die(reason: "A trickster caught you!")
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
            checkpoint.node.alpha = 0.45
            checkpoint.node.run(.sequence([
                .scale(to: 1.3, duration: 0.15), .scale(to: 1, duration: 0.15),
            ]))
            checkpointSnapshot = CheckpointSnapshot(
                scroll: scroll,
                coins: coins.map(\.collected),
                gates: gates.map(\.passed),
                springs: springs.map(\.activated),
                stars: challengeStars.map(\.collected),
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
        player.flashDead()
        player.run(.sequence([.scale(to: 1.4, duration: 0.1), .scale(to: 0, duration: 0.2)]))
        game?.died(reason: reason)
    }

    // MARK: External control

    /// Configure the scene for a level and reset it, ready to `begin()`.
    func load(words: [VocabWord], difficulty: Difficulty, skin: Skin, seed: UInt64 = 0) {
        self.words = words
        self.difficulty = difficulty
        self.skin = skin
        levelSeed = seed
        rebuild()
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
        level = Level.generate(words: words, difficulty: difficulty, seed: levelSeed)
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
        restore(snapshot.shields, to: shields, keyPath: \.collected)
        restore(snapshot.checkpoints, to: checkpoints, keyPath: \.activated)
        for coin in coins where coin.collected { coin.node.removeFromParent() }
        for gate in gates where gate.passed { gate.node.alpha = 0.45 }
        for star in challengeStars where star.collected { star.node.removeFromParent() }
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
