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
    private let playerSize: CGFloat = 44

    // MARK: World state
    private var words: [VocabWord] = Campaign.themes[0].words
    private var difficulty: Difficulty = .forLevel(0)
    private var level = Level.generate(words: Campaign.themes[0].words, difficulty: .forLevel(0))
    private var scroll: CGFloat = 0
    private var playerY: CGFloat = 0   // height above the ground surface
    private var vy: CGFloat = 0
    private var onGround = true
    private var holding = false
    private var holdTime: TimeInterval = 0
    private var active = false
    private var lastUpdate: TimeInterval = 0
    private var pendingWord: VocabWord?

    // MARK: Nodes
    private let worldNode = SKNode()
    private let player = SKSpriteNode(color: .systemYellow, size: .zero)
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
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1) // sky
        addChild(worldNode)
        player.size = CGSize(width: playerSize, height: playerSize)
        player.zPosition = 10
        addChild(player)
        rebuild()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // Reposition the player any time the view resizes (macOS window, rotation).
        player.position = CGPoint(x: playerScreenX, y: groundTopY + playerSize / 2 + playerY)
    }

    private func buildWorld() {
        worldNode.removeAllChildren()
        coins.removeAll()
        gates.removeAll()
        spikes.removeAll()

        // Ground segments as dark green platforms extending below the surface.
        for seg in level.segments {
            let w = seg.endX - seg.startX
            let node = SKSpriteNode(color: SKColor(red: 0.29, green: 0.6, blue: 0.32, alpha: 1),
                                    size: CGSize(width: w, height: 2000))
            node.anchorPoint = CGPoint(x: 0, y: 1)
            node.position = CGPoint(x: seg.startX, y: 0) // y set each frame relative to groundTopY
            node.name = "ground"
            worldNode.addChild(node)
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

        // Finish banner.
        let finish = SKSpriteNode(color: .systemPurple, size: CGSize(width: 16, height: 260))
        finish.anchorPoint = CGPoint(x: 0.5, y: 0)
        finish.name = "finish"
        finish.position = CGPoint(x: level.finishX, y: 0)
        worldNode.addChild(finish)

        layoutWorldHeights()
    }

    private func makeSpike(at x: CGFloat) -> SKNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -22, y: 0))
        path.addLine(to: CGPoint(x: 0, y: 44))
        path.addLine(to: CGPoint(x: 22, y: 0))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = SKColor(red: 0.85, green: 0.2, blue: 0.2, alpha: 1)
        node.strokeColor = .clear
        node.name = "spike"
        node.position = CGPoint(x: x, y: 0)
        return node
    }

    private func makeCoin(at x: CGFloat) -> SKNode {
        let node = SKShapeNode(circleOfRadius: 20)
        node.fillColor = SKColor(red: 1, green: 0.84, blue: 0.2, alpha: 1)
        node.strokeColor = SKColor(red: 0.85, green: 0.6, blue: 0.1, alpha: 1)
        node.lineWidth = 3
        node.name = "coin"
        node.position = CGPoint(x: x, y: 0)
        node.run(.repeatForever(.sequence([
            .scale(to: 1.15, duration: 0.5), .scale(to: 1.0, duration: 0.5),
        ])))
        return node
    }

    private func makeGate(at x: CGFloat) -> SKNode {
        let node = SKSpriteNode(color: SKColor(white: 1, alpha: 0.85),
                                size: CGSize(width: 10, height: 220))
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.name = "gate"
        node.position = CGPoint(x: x, y: 0)
        let q = SKLabelNode(text: "?")
        q.fontName = "AvenirNext-Bold"
        q.fontSize = 44
        q.fontColor = .systemIndigo
        q.position = CGPoint(x: 0, y: 240)
        node.addChild(q)
        return node
    }

    /// Ground and world objects live at y=0 in `worldNode`; anchor them to the
    /// current ground surface every layout so resizing stays correct.
    private func layoutWorldHeights() {
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        for c in coins { c.node.position.y = 90 }
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

        // Render.
        worldNode.position = CGPoint(x: -scroll, y: groundTopY)
        player.position = CGPoint(x: playerScreenX, y: groundTopY + playerSize / 2 + playerY)
        player.zRotation = onGround ? 0 : max(-0.5, -vy / 4000)
        game?.updateDistance(Int(scroll / 100))
    }

    private func checkSpikes(worldX: CGFloat) {
        guard playerY < 40 else { return } // above the spike tips
        for sx in spikes where abs(sx - worldX) < 22 {
            die(reason: "Ouch — spikes!")
            return
        }
    }

    private func checkCoins(worldX: CGFloat) {
        for c in coins where !c.collected {
            if abs(c.x - worldX) < 34 && abs(playerY - 90) < 90 {
                c.collected = true
                c.node.run(.sequence([.group([.scale(to: 1.8, duration: 0.2),
                                              .fadeOut(withDuration: 0.2)]), .removeFromParent()]))
                pendingWord = c.word
                game?.collected(c.word)
            }
        }
    }

    private func checkGates(worldX: CGFloat) {
        for gate in gates where !gate.passed {
            if worldX >= gate.x {
                gate.passed = true
                if let word = pendingWord {
                    active = false
                    game?.presentQuiz(for: word)
                }
            }
        }
    }

    private func die(reason: String) {
        guard active else { return }
        active = false
        player.color = .systemRed
        player.run(.sequence([.scale(to: 1.4, duration: 0.1), .scale(to: 0, duration: 0.2)]))
        game?.died(reason: reason)
    }

    // MARK: External control

    /// Configure the scene for a level and reset it, ready to `begin()`.
    func load(words: [VocabWord], difficulty: Difficulty) {
        self.words = words
        self.difficulty = difficulty
        rebuild()
    }

    /// Start (or resume from the level intro) running the level.
    func begin() {
        active = true
    }

    func resumeFromGate() {
        pendingWord = nil
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
        pendingWord = nil
        lastUpdate = 0
        active = false
        player.color = .systemYellow
        player.setScale(1)
        player.zRotation = 0
        buildWorld()
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
