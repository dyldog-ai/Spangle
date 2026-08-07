import SpriteKit

/// A friendly custom-drawn character used as the player. Built from vector
/// shapes so it looks consistent on every level and needs no art assets.
final class PlayerNode: SKNode {
    private let body = SKShapeNode()
    private let leftFoot = SKShapeNode(ellipseOf: CGSize(width: 16, height: 9))
    private let rightFoot = SKShapeNode(ellipseOf: CGSize(width: 16, height: 9))

    init(size: CGFloat) {
        super.init()
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size s: CGFloat) {
        let half = s / 2
        let bodyColor = SKColor(red: 1, green: 0.72, blue: 0.2, alpha: 1)
        let outline = SKColor(red: 0.35, green: 0.2, blue: 0.05, alpha: 1)

        // Feet (behind the body).
        for (foot, dx) in [(leftFoot, -half * 0.45), (rightFoot, half * 0.45)] {
            foot.fillColor = outline
            foot.strokeColor = .clear
            foot.position = CGPoint(x: dx, y: -half + 2)
            addChild(foot)
        }

        // Rounded body.
        body.path = CGPath(roundedRect: CGRect(x: -half, y: -half, width: s, height: s),
                           cornerWidth: s * 0.32, cornerHeight: s * 0.32, transform: nil)
        body.fillColor = bodyColor
        body.strokeColor = outline
        body.lineWidth = 3
        addChild(body)

        // Belly highlight.
        let belly = SKShapeNode(ellipseOf: CGSize(width: s * 0.5, height: s * 0.42))
        belly.fillColor = bodyColor.lighter(0.35)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -half * 0.35)
        body.addChild(belly)

        // Eyes.
        for dx in [-half * 0.32, half * 0.32] {
            let white = SKShapeNode(circleOfRadius: s * 0.15)
            white.fillColor = .white
            white.strokeColor = outline
            white.lineWidth = 2
            white.position = CGPoint(x: dx, y: half * 0.28)
            let pupil = SKShapeNode(circleOfRadius: s * 0.07)
            pupil.fillColor = outline
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: dx + s * 0.04, y: half * 0.28)
            body.addChild(white)
            body.addChild(pupil)
        }

        // Smile.
        let smile = SKShapeNode()
        let p = CGMutablePath()
        p.addArc(center: CGPoint(x: 0, y: -half * 0.02), radius: s * 0.2,
                 startAngle: .pi * 1.15, endAngle: .pi * 1.85, clockwise: false)
        smile.path = p
        smile.strokeColor = outline
        smile.lineWidth = 2.5
        smile.lineCap = .round
        body.addChild(smile)

        // Gentle idle bob.
        body.run(.repeatForever(.sequence([
            .scaleY(to: 1.04, duration: 0.5), .scaleY(to: 1.0, duration: 0.5),
        ])))
    }

    /// Quick stretch when leaving the ground.
    func squashJump() {
        body.removeAction(forKey: "squash")
        body.run(.sequence([.scale(to: 1.0, duration: 0),
                            .scaleX(to: 0.85, duration: 0.08),
                            .scaleX(to: 1.0, duration: 0.12)]), withKey: "squash")
    }

    /// Reset appearance (used on restart after a red death flash).
    func setAlive() {
        body.fillColor = SKColor(red: 1, green: 0.72, blue: 0.2, alpha: 1)
        setScale(1)
        zRotation = 0
        alpha = 1
    }

    func flashDead() {
        body.fillColor = SKColor(red: 0.9, green: 0.25, blue: 0.2, alpha: 1)
    }
}
