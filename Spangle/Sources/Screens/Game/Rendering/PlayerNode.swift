import SpriteKit

/// Sol, Spangle's hand-drawn golden storybook mascot.
final class PlayerNode: SKNode {
    private let body = SKShapeNode()
    private let leftFoot = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
    private let rightFoot = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
    private let leftArm = SKShapeNode()
    private let rightArm = SKShapeNode()
    private let scarfTail = SKShapeNode()
    private let warmGold = SKColor(red: 1, green: 0.67, blue: 0.18, alpha: 1)
    private let ink = SKColor(red: 0.25, green: 0.13, blue: 0.08, alpha: 1)

    init(size: CGFloat) {
        super.init()
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size s: CGFloat) {
        let half = s / 2

        addScarfTail(size: s)
        addArms(size: s)

        for (foot, dx, delay) in [(leftFoot, -half * 0.46, 0.0),
                                  (rightFoot, half * 0.46, 0.16)] {
            foot.fillColor = ink
            foot.strokeColor = ink.darker(0.15)
            foot.lineWidth = 1.5
            foot.position = CGPoint(x: dx, y: -half + 1)
            foot.zRotation = dx < 0 ? 0.08 : -0.08
            addChild(foot)
            foot.run(.repeatForever(.sequence([
                .wait(forDuration: delay),
                .moveBy(x: 0, y: 3, duration: 0.08),
                .moveBy(x: 0, y: -3, duration: 0.08),
                .wait(forDuration: max(0, 0.32 - delay)),
            ])))
        }

        let bodyPath = CGPath(
            roundedRect: CGRect(x: -half, y: -half, width: s, height: s),
            cornerWidth: s * 0.34,
            cornerHeight: s * 0.34,
            transform: nil
        )
        let bodyShadow = SKShapeNode(path: bodyPath)
        bodyShadow.fillColor = ink.withAlphaComponent(0.22)
        bodyShadow.strokeColor = .clear
        bodyShadow.position = CGPoint(x: 2.5, y: -3)
        addChild(bodyShadow)

        body.path = bodyPath
        body.fillColor = warmGold
        body.strokeColor = ink
        body.lineWidth = 2.8
        body.lineJoin = .round
        addChild(body)

        addFace(size: s)
        addScarf(size: s)
        addPaintedDetails(size: s)

        body.run(.repeatForever(.sequence([
            .scaleY(to: 1.025, duration: 0.34),
            .scaleY(to: 0.985, duration: 0.34),
        ])), withKey: "breathing")
    }

    private func addArms(size s: CGFloat) {
        for (arm, direction) in [(leftArm, -1.0), (rightArm, 1.0)] {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: CGFloat(direction) * s * 0.37, y: 2))
            path.addQuadCurve(
                to: CGPoint(x: CGFloat(direction) * s * 0.62, y: -s * 0.08),
                control: CGPoint(x: CGFloat(direction) * s * 0.56, y: s * 0.09)
            )
            arm.path = path
            arm.strokeColor = ink
            arm.lineWidth = 5
            arm.lineCap = .round
            arm.fillColor = .clear
            addChild(arm)
            arm.run(.repeatForever(.sequence([
                .rotate(toAngle: CGFloat(direction) * -0.16, duration: 0.16),
                .rotate(toAngle: CGFloat(direction) * 0.12, duration: 0.16),
            ])))
        }
    }

    private func addScarfTail(size s: CGFloat) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: s * 0.3, y: -s * 0.16))
        path.addCurve(
            to: CGPoint(x: s * 0.75, y: -s * 0.25),
            control1: CGPoint(x: s * 0.48, y: -s * 0.1),
            control2: CGPoint(x: s * 0.6, y: -s * 0.34)
        )
        path.addLine(to: CGPoint(x: s * 0.68, y: -s * 0.42))
        path.addCurve(
            to: CGPoint(x: s * 0.25, y: -s * 0.28),
            control1: CGPoint(x: s * 0.53, y: -s * 0.31),
            control2: CGPoint(x: s * 0.43, y: -s * 0.3)
        )
        path.closeSubpath()
        scarfTail.path = path
        scarfTail.fillColor = SKColor(red: 0.78, green: 0.16, blue: 0.12, alpha: 1)
        scarfTail.strokeColor = ink
        scarfTail.lineWidth = 2
        addChild(scarfTail)
        scarfTail.run(.repeatForever(.sequence([
            .rotate(toAngle: 0.1, duration: 0.24),
            .rotate(toAngle: -0.06, duration: 0.24),
        ])))
    }

    private func addFace(size s: CGFloat) {
        let half = s / 2
        for dx in [-half * 0.31, half * 0.31] {
            let eye = SKShapeNode(ellipseOf: CGSize(width: s * 0.25, height: s * 0.31))
            eye.fillColor = SKColor(red: 1, green: 0.98, blue: 0.9, alpha: 1)
            eye.strokeColor = ink
            eye.lineWidth = 1.8
            eye.position = CGPoint(x: dx, y: half * 0.25)
            body.addChild(eye)

            let pupil = SKShapeNode(ellipseOf: CGSize(width: s * 0.1, height: s * 0.14))
            pupil.fillColor = ink
            pupil.strokeColor = .clear
            pupil.position = CGPoint(x: s * 0.025, y: -s * 0.005)
            eye.addChild(pupil)

            let glint = SKShapeNode(circleOfRadius: s * 0.022)
            glint.fillColor = .white
            glint.strokeColor = .clear
            glint.position = CGPoint(x: s * 0.02, y: s * 0.035)
            pupil.addChild(glint)
        }

        let smile = SKShapeNode()
        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -s * 0.19, y: -s * 0.08))
        smilePath.addCurve(
            to: CGPoint(x: s * 0.19, y: -s * 0.08),
            control1: CGPoint(x: -s * 0.1, y: -s * 0.2),
            control2: CGPoint(x: s * 0.1, y: -s * 0.2)
        )
        smile.path = smilePath
        smile.strokeColor = ink
        smile.lineWidth = 2.5
        smile.lineCap = .round
        body.addChild(smile)

        for x in [-s * 0.29, s * 0.29] {
            let cheek = SKShapeNode(ellipseOf: CGSize(width: s * 0.13, height: s * 0.065))
            cheek.fillColor = SKColor(red: 0.93, green: 0.31, blue: 0.22, alpha: 0.35)
            cheek.strokeColor = .clear
            cheek.position = CGPoint(x: x, y: -s * 0.05)
            body.addChild(cheek)
        }
    }

    private func addScarf(size s: CGFloat) {
        let scarf = SKShapeNode()
        scarf.path = CGPath(
            roundedRect: CGRect(x: -s * 0.38, y: -s * 0.31, width: s * 0.76, height: s * 0.15),
            cornerWidth: s * 0.07,
            cornerHeight: s * 0.07,
            transform: nil
        )
        scarf.fillColor = SKColor(red: 0.88, green: 0.23, blue: 0.16, alpha: 1)
        scarf.strokeColor = ink
        scarf.lineWidth = 1.8
        body.addChild(scarf)

        let knot = SKShapeNode(circleOfRadius: s * 0.085)
        knot.fillColor = SKColor(red: 1, green: 0.76, blue: 0.18, alpha: 1)
        knot.strokeColor = ink
        knot.lineWidth = 1.5
        knot.position = CGPoint(x: s * 0.27, y: -s * 0.235)
        body.addChild(knot)
    }

    private func addPaintedDetails(size s: CGFloat) {
        let highlight = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -s * 0.31, y: s * 0.08))
        path.addQuadCurve(
            to: CGPoint(x: -s * 0.22, y: s * 0.31),
            control: CGPoint(x: -s * 0.34, y: s * 0.22)
        )
        highlight.path = path
        highlight.strokeColor = .white.withAlphaComponent(0.34)
        highlight.lineWidth = 3
        highlight.lineCap = .round
        body.addChild(highlight)

        let belly = SKShapeNode(ellipseOf: CGSize(width: s * 0.48, height: s * 0.23))
        belly.fillColor = SKColor(red: 1, green: 0.86, blue: 0.45, alpha: 0.55)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -s * 0.28)
        body.addChild(belly)
    }

    /// Quick squash-and-stretch when leaving the ground.
    func squashJump() {
        removeAction(forKey: "squash")
        run(.sequence([
            .group([.scaleX(to: 1.14, duration: 0.055), .scaleY(to: 0.84, duration: 0.055)]),
            .group([.scaleX(to: 0.88, duration: 0.075), .scaleY(to: 1.16, duration: 0.075)]),
            .scale(to: 1, duration: 0.12),
        ]), withKey: "squash")
    }

    func setAlive() {
        body.fillColor = warmGold
        removeAction(forKey: "squash")
        setScale(1)
        zRotation = 0
        alpha = 1
    }

    func flashDead() {
        body.fillColor = SKColor(red: 0.91, green: 0.3, blue: 0.2, alpha: 1)
    }
}
