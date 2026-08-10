import SpriteKit

/// Sol, Spangle's hand-drawn golden storybook mascot.
final class PlayerNode: SKNode {
    private let body = SKShapeNode()
    private let leftFoot = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
    private let rightFoot = SKShapeNode(ellipseOf: CGSize(width: 18, height: 9))
    private let leftArm = SKShapeNode()
    private let rightArm = SKShapeNode()
    private let scarfTail = SKShapeNode()
    private let scarf = SKShapeNode()
    private let scarfKnot = SKShapeNode(circleOfRadius: 4)
    private let belly = SKShapeNode()
    private let smile = SKShapeNode()
    private let auraLayer = SKNode()
    private let accessoryLayer = SKNode()
    private let warmGold = SKColor(red: 1, green: 0.67, blue: 0.18, alpha: 1)
    private let ink = SKColor(red: 0.25, green: 0.13, blue: 0.08, alpha: 1)
    private var activeBodyColor = SKColor(red: 1, green: 0.67, blue: 0.18, alpha: 1)
    private let characterSize: CGFloat

    init(size: CGFloat) {
        characterSize = size
        super.init()
        build(size: size)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func build(size s: CGFloat) {
        let half = s / 2

        auraLayer.zPosition = -4
        addChild(auraLayer)
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
        accessoryLayer.zPosition = 8
        addChild(accessoryLayer)

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
            eye.zPosition = 4
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

        let smilePath = CGMutablePath()
        smilePath.move(to: CGPoint(x: -s * 0.19, y: -s * 0.08))
        smilePath.addCurve(
            to: CGPoint(x: s * 0.19, y: -s * 0.08),
            control1: CGPoint(x: -s * 0.1, y: -s * 0.2),
            control2: CGPoint(x: s * 0.1, y: -s * 0.2)
        )
        smile.path = smilePath
        smile.name = "mouth"
        smile.strokeColor = ink
        smile.lineWidth = 2.5
        smile.lineCap = .round
        smile.zPosition = 5
        body.addChild(smile)

        for direction in [-1.0, 1.0] as [CGFloat] {
            let brow = SKShapeNode()
            let browPath = CGMutablePath()
            browPath.move(to: CGPoint(x: direction * s * 0.16, y: s * 0.31))
            browPath.addLine(to: CGPoint(x: direction * s * 0.38, y: s * 0.35))
            brow.path = browPath
            brow.strokeColor = ink
            brow.lineWidth = 2
            brow.lineCap = .round
            brow.zPosition = 5
            body.addChild(brow)
        }

        for x in [-s * 0.29, s * 0.29] {
            let cheek = SKShapeNode(ellipseOf: CGSize(width: s * 0.13, height: s * 0.065))
            cheek.fillColor = SKColor(red: 0.93, green: 0.31, blue: 0.22, alpha: 0.35)
            cheek.strokeColor = .clear
            cheek.position = CGPoint(x: x, y: -s * 0.05)
            cheek.zPosition = 3
            body.addChild(cheek)
        }
    }

    private func addScarf(size s: CGFloat) {
        scarf.path = CGPath(
            roundedRect: CGRect(x: -s * 0.38, y: -s * 0.31, width: s * 0.76, height: s * 0.15),
            cornerWidth: s * 0.07,
            cornerHeight: s * 0.07,
            transform: nil
        )
        scarf.name = "scarf"
        scarf.fillColor = SKColor(red: 0.88, green: 0.23, blue: 0.16, alpha: 1)
        scarf.strokeColor = ink
        scarf.lineWidth = 1.8
        scarf.zPosition = 1
        body.addChild(scarf)

        scarfKnot.path = CGPath(ellipseIn: CGRect(x: -s * 0.085, y: -s * 0.085,
                                                   width: s * 0.17, height: s * 0.17),
                                     transform: nil)
        scarfKnot.fillColor = SKColor(red: 1, green: 0.76, blue: 0.18, alpha: 1)
        scarfKnot.strokeColor = ink
        scarfKnot.lineWidth = 1.5
        scarfKnot.position = CGPoint(x: s * 0.27, y: -s * 0.235)
        scarfKnot.zPosition = 2
        body.addChild(scarfKnot)
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

        belly.path = CGPath(ellipseIn: CGRect(x: -s * 0.24, y: -s * 0.115,
                                               width: s * 0.48, height: s * 0.23),
                                 transform: nil)
        belly.name = "belly"
        belly.fillColor = SKColor(red: 1, green: 0.86, blue: 0.45, alpha: 0.55)
        belly.strokeColor = .clear
        belly.position = CGPoint(x: 0, y: -s * 0.31)
        belly.zPosition = 0
        body.addChild(belly)
    }

    func apply(design: CharacterDesign) {
        accessoryLayer.removeAllActions()
        accessoryLayer.removeAllChildren()
        auraLayer.removeAllActions()
        auraLayer.removeAllChildren()

        let red = SKColor(red: 0.88, green: 0.23, blue: 0.16, alpha: 1)
        activeBodyColor = warmGold
        var secondary = SKColor(red: 1, green: 0.86, blue: 0.45, alpha: 0.55)
        var scarfColor = red
        var knotColor = SKColor(red: 1, green: 0.76, blue: 0.18, alpha: 1)
        smile.isHidden = false
        leftFoot.fillColor = ink
        rightFoot.fillColor = ink

        switch design.style {
        case .sol:
            addSunPin()
        case .coral:
            activeBodyColor = SKColor(red: 0.97, green: 0.34, blue: 0.25, alpha: 1)
            secondary = SKColor(red: 1, green: 0.67, blue: 0.3, alpha: 0.55)
            scarfColor = SKColor(red: 0.1, green: 0.48, blue: 0.62, alpha: 1)
            addExplorerCap(color: SKColor(red: 0.12, green: 0.52, blue: 0.64, alpha: 1))
        case .forest:
            activeBodyColor = SKColor(red: 0.2, green: 0.62, blue: 0.32, alpha: 1)
            secondary = SKColor(red: 0.65, green: 0.86, blue: 0.34, alpha: 0.55)
            scarfColor = SKColor(red: 1, green: 0.78, blue: 0.25, alpha: 1)
            addLeafCrown()
        case .midnight:
            activeBodyColor = SKColor(red: 0.11, green: 0.12, blue: 0.28, alpha: 1)
            secondary = SKColor(red: 0.38, green: 0.3, blue: 0.68, alpha: 0.5)
            scarfColor = .black
            knotColor = SKColor(red: 0.45, green: 0.32, blue: 0.85, alpha: 1)
            addHeadband(color: knotColor)
        case .fiesta:
            activeBodyColor = SKColor(red: 0.95, green: 0.24, blue: 0.5, alpha: 1)
            secondary = SKColor(red: 1, green: 0.65, blue: 0.2, alpha: 0.55)
            scarfColor = SKColor(red: 1, green: 0.57, blue: 0.08, alpha: 1)
            addFlowerCrown()
        case .ocean:
            activeBodyColor = SKColor(red: 0.05, green: 0.46, blue: 0.68, alpha: 1)
            secondary = SKColor(red: 0.2, green: 0.84, blue: 0.9, alpha: 0.5)
            scarfColor = .white
            knotColor = SKColor(red: 0.95, green: 0.62, blue: 0.08, alpha: 1)
            addCaptainHat()
        case .clockwork:
            activeBodyColor = SKColor(red: 0.64, green: 0.36, blue: 0.14, alpha: 1)
            secondary = SKColor(red: 0.95, green: 0.65, blue: 0.18, alpha: 0.6)
            scarfColor = SKColor(red: 0.16, green: 0.45, blue: 0.45, alpha: 1)
            addClockworkKey()
        case .astronaut:
            activeBodyColor = SKColor(red: 0.82, green: 0.87, blue: 0.94, alpha: 1)
            secondary = SKColor(red: 0.35, green: 0.54, blue: 0.75, alpha: 0.42)
            scarfColor = .white
            knotColor = SKColor(red: 0.12, green: 0.48, blue: 0.68, alpha: 1)
            addSpaceHelmet()
        case .knight:
            activeBodyColor = SKColor(red: 0.94, green: 0.66, blue: 0.12, alpha: 1)
            secondary = SKColor(red: 1, green: 0.9, blue: 0.46, alpha: 0.58)
            scarfColor = SKColor(red: 0.67, green: 0.08, blue: 0.08, alpha: 1)
            addKnightHelm()
        case .dragon:
            activeBodyColor = SKColor(red: 0.08, green: 0.64, blue: 0.52, alpha: 1)
            secondary = SKColor(red: 0.3, green: 0.9, blue: 0.68, alpha: 0.5)
            scarfColor = SKColor(red: 0.34, green: 0.16, blue: 0.6, alpha: 1)
            addDragonRegalia()
            addAura(colors: [.cyan, SKColor(red: 0.45, green: 0.2, blue: 0.8, alpha: 1)])
        case .aurora:
            activeBodyColor = SKColor(red: 0.35, green: 0.18, blue: 0.64, alpha: 1)
            secondary = SKColor(red: 0.25, green: 0.9, blue: 0.82, alpha: 0.56)
            scarfColor = SKColor(red: 0.06, green: 0.12, blue: 0.2, alpha: 1)
            addCrown(color: .cyan)
            addAura(colors: [.cyan, .systemPink, .systemPurple])
        case .legend:
            activeBodyColor = SKColor(red: 0.98, green: 0.72, blue: 0.15, alpha: 1)
            secondary = .white.withAlphaComponent(0.62)
            scarfColor = SKColor(red: 0.14, green: 0.08, blue: 0.2, alpha: 1)
            knotColor = .white
            addCrown(color: .white)
            addAura(colors: [.systemRed, .systemOrange, .systemYellow,
                             .systemGreen, .systemBlue, .systemPurple])
            addOrbitingStars()
        case .isaac:
            activeBodyColor = SKColor(red: 0.94, green: 0.82, blue: 0.72, alpha: 1)
            secondary = SKColor(red: 0.78, green: 0.62, blue: 0.52, alpha: 0.28)
            scarfColor = SKColor(red: 0.36, green: 0.58, blue: 0.72, alpha: 1)
            smile.isHidden = true
            addIsaacTears()
        case .moonwalker:
            activeBodyColor = SKColor(red: 0.18, green: 0.17, blue: 0.2, alpha: 1)
            secondary = .white.withAlphaComponent(0.2)
            scarfColor = .white
            knotColor = .systemRed
            addFedoraAndGlove()
        case .stardust:
            activeBodyColor = SKColor(red: 0.86, green: 0.42, blue: 0.2, alpha: 1)
            secondary = SKColor(red: 0.2, green: 0.58, blue: 0.82, alpha: 0.48)
            scarfColor = SKColor(red: 0.1, green: 0.46, blue: 0.74, alpha: 1)
            addStardustFlash()
        case .sleuth:
            activeBodyColor = SKColor(red: 0.62, green: 0.46, blue: 0.28, alpha: 1)
            secondary = SKColor(red: 0.86, green: 0.75, blue: 0.5, alpha: 0.46)
            scarfColor = SKColor(red: 0.34, green: 0.16, blue: 0.1, alpha: 1)
            addSleuthKit()
        case .plumber:
            activeBodyColor = SKColor(red: 0.9, green: 0.18, blue: 0.14, alpha: 1)
            secondary = SKColor(red: 0.12, green: 0.32, blue: 0.72, alpha: 0.56)
            scarfColor = SKColor(red: 0.08, green: 0.25, blue: 0.66, alpha: 1)
            smile.isHidden = true
            addPlumberGear()
        case .speedster:
            activeBodyColor = SKColor(red: 0.06, green: 0.32, blue: 0.78, alpha: 1)
            secondary = SKColor(red: 0.96, green: 0.78, blue: 0.42, alpha: 0.5)
            scarfColor = .systemRed
            addSpeedsterSpikes()
        }

        body.fillColor = activeBodyColor
        belly.fillColor = secondary
        scarf.fillColor = scarfColor
        scarfTail.fillColor = scarfColor.darker(0.08)
        scarfKnot.fillColor = knotColor
    }

    private func addSunPin() {
        let pin = SKShapeNode(circleOfRadius: characterSize * 0.07)
        pin.fillColor = SKColor(red: 1, green: 0.9, blue: 0.3, alpha: 1)
        pin.strokeColor = ink
        pin.lineWidth = 1
        pin.position = CGPoint(x: -characterSize * 0.25, y: -characterSize * 0.23)
        accessoryLayer.addChild(pin)
    }

    private func addExplorerCap(color: SKColor) {
        let crown = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.72,
                                                  height: characterSize * 0.24))
        crown.fillColor = color
        crown.strokeColor = ink
        crown.lineWidth = 2
        crown.position.y = characterSize * 0.5
        accessoryLayer.addChild(crown)
        let brim = SKShapeNode(rectOf: CGSize(width: characterSize * 0.48,
                                              height: characterSize * 0.08), cornerRadius: 2)
        brim.fillColor = color.darker(0.12)
        brim.strokeColor = ink
        brim.lineWidth = 1.5
        brim.position = CGPoint(x: characterSize * 0.23, y: characterSize * 0.43)
        accessoryLayer.addChild(brim)
    }

    private func addLeafCrown() {
        for (index, x) in ([-0.27, 0, 0.27] as [CGFloat]).enumerated() {
            let leaf = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.18,
                                                     height: characterSize * 0.38))
            leaf.fillColor = index.isMultiple(of: 2) ? .systemGreen : .systemYellow
            leaf.strokeColor = ink
            leaf.lineWidth = 1.4
            leaf.position = CGPoint(x: characterSize * x, y: characterSize * 0.55)
            leaf.zRotation = characterSize * x * -0.018
            accessoryLayer.addChild(leaf)
        }
    }

    private func addHeadband(color: SKColor) {
        let band = SKShapeNode(rectOf: CGSize(width: characterSize * 0.92,
                                              height: characterSize * 0.13), cornerRadius: 3)
        band.fillColor = color
        band.strokeColor = ink
        band.lineWidth = 1.5
        band.position.y = characterSize * 0.45
        accessoryLayer.addChild(band)
        let tail = SKShapeNode(rectOf: CGSize(width: characterSize * 0.35,
                                              height: characterSize * 0.1), cornerRadius: 2)
        tail.fillColor = color
        tail.strokeColor = ink
        tail.lineWidth = 1.2
        tail.position = CGPoint(x: characterSize * 0.55, y: characterSize * 0.38)
        tail.zRotation = -0.25
        accessoryLayer.addChild(tail)
    }

    private func addFlowerCrown() {
        let colors: [SKColor] = [.systemPink, .systemYellow, .systemOrange, .white]
        for index in 0..<5 {
            let flower = SKShapeNode(circleOfRadius: characterSize * 0.085)
            flower.fillColor = colors[index % colors.count]
            flower.strokeColor = ink
            flower.lineWidth = 1.2
            flower.position = CGPoint(x: characterSize * (CGFloat(index) - 2) * 0.16,
                                      y: characterSize * (0.49 + (index.isMultiple(of: 2) ? 0.05 : 0)))
            accessoryLayer.addChild(flower)
        }
    }

    private func addCaptainHat() {
        let hat = SKShapeNode(rectOf: CGSize(width: characterSize * 0.78,
                                             height: characterSize * 0.25), cornerRadius: 5)
        hat.fillColor = .white
        hat.strokeColor = ink
        hat.lineWidth = 2
        hat.position.y = characterSize * 0.51
        accessoryLayer.addChild(hat)
        let band = SKShapeNode(rectOf: CGSize(width: characterSize * 0.82,
                                              height: characterSize * 0.07), cornerRadius: 2)
        band.fillColor = SKColor(red: 0.08, green: 0.35, blue: 0.58, alpha: 1)
        band.strokeColor = ink
        band.lineWidth = 1
        band.position.y = characterSize * 0.43
        accessoryLayer.addChild(band)
    }

    private func addClockworkKey() {
        let ring = SKShapeNode(circleOfRadius: characterSize * 0.13)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 0.95, green: 0.68, blue: 0.2, alpha: 1)
        ring.lineWidth = 3
        ring.position = CGPoint(x: characterSize * 0.42, y: characterSize * 0.2)
        accessoryLayer.addChild(ring)
        let stem = SKShapeNode(rectOf: CGSize(width: 3, height: characterSize * 0.36), cornerRadius: 1.5)
        stem.fillColor = ring.strokeColor
        stem.strokeColor = ink
        stem.lineWidth = 1
        stem.position = CGPoint(x: characterSize * 0.42, y: characterSize * 0.42)
        accessoryLayer.addChild(stem)
        ring.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 2.4)))
    }

    private func addSpaceHelmet() {
        let helmet = SKShapeNode(circleOfRadius: characterSize * 0.62)
        helmet.fillColor = SKColor(red: 0.5, green: 0.85, blue: 1, alpha: 0.1)
        helmet.strokeColor = .white.withAlphaComponent(0.9)
        helmet.lineWidth = 3
        accessoryLayer.addChild(helmet)
        let antenna = SKShapeNode(rectOf: CGSize(width: 3, height: characterSize * 0.3), cornerRadius: 1.5)
        antenna.fillColor = .white
        antenna.strokeColor = ink
        antenna.lineWidth = 1
        antenna.position = CGPoint(x: characterSize * 0.38, y: characterSize * 0.63)
        antenna.zRotation = -0.35
        accessoryLayer.addChild(antenna)
        let light = SKShapeNode(circleOfRadius: characterSize * 0.07)
        light.fillColor = .systemRed
        light.strokeColor = ink
        light.lineWidth = 1
        light.position = CGPoint(x: characterSize * 0.43, y: characterSize * 0.78)
        accessoryLayer.addChild(light)
    }

    private func addKnightHelm() {
        let crest = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -characterSize * 0.16, y: characterSize * 0.48))
        path.addQuadCurve(to: CGPoint(x: 0, y: characterSize * 0.86),
                          control: CGPoint(x: -characterSize * 0.08, y: characterSize * 0.76))
        path.addQuadCurve(to: CGPoint(x: characterSize * 0.18, y: characterSize * 0.48),
                          control: CGPoint(x: characterSize * 0.08, y: characterSize * 0.76))
        path.closeSubpath()
        crest.path = path
        crest.fillColor = SKColor(red: 0.72, green: 0.06, blue: 0.08, alpha: 1)
        crest.strokeColor = ink
        crest.lineWidth = 2
        accessoryLayer.addChild(crest)
        addCrown(color: SKColor(red: 0.95, green: 0.73, blue: 0.18, alpha: 1))
    }

    private func addDragonRegalia() {
        addWings(color: SKColor(red: 0.32, green: 0.14, blue: 0.55, alpha: 1))
        for direction in [-1.0, 1.0] as [CGFloat] {
            let horn = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: direction * characterSize * 0.2, y: characterSize * 0.43))
            path.addLine(to: CGPoint(x: direction * characterSize * 0.48, y: characterSize * 0.78))
            path.addLine(to: CGPoint(x: direction * characterSize * 0.43, y: characterSize * 0.38))
            path.closeSubpath()
            horn.path = path
            horn.fillColor = .cyan
            horn.strokeColor = ink
            horn.lineWidth = 1.5
            accessoryLayer.addChild(horn)
        }
    }

    private func addWings(color: SKColor) {
        for direction in [-1.0, 1.0] as [CGFloat] {
            let wing = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: direction * characterSize * 0.32, y: characterSize * 0.12))
            path.addQuadCurve(to: CGPoint(x: direction * characterSize * 0.92, y: characterSize * 0.34),
                              control: CGPoint(x: direction * characterSize * 0.72, y: characterSize * 0.54))
            path.addLine(to: CGPoint(x: direction * characterSize * 0.72, y: -characterSize * 0.06))
            path.addLine(to: CGPoint(x: direction * characterSize * 0.38, y: -characterSize * 0.16))
            path.closeSubpath()
            wing.path = path
            wing.fillColor = color
            wing.strokeColor = ink
            wing.lineWidth = 2
            accessoryLayer.addChild(wing)
            wing.run(.repeatForever(.sequence([
                .rotate(toAngle: direction * 0.11, duration: 0.24),
                .rotate(toAngle: direction * -0.08, duration: 0.24),
            ])))
        }
    }

    private func addCrown(color: SKColor) {
        let crown = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -characterSize * 0.3, y: characterSize * 0.45))
        path.addLine(to: CGPoint(x: -characterSize * 0.28, y: characterSize * 0.76))
        path.addLine(to: CGPoint(x: -characterSize * 0.08, y: characterSize * 0.58))
        path.addLine(to: CGPoint(x: 0, y: characterSize * 0.84))
        path.addLine(to: CGPoint(x: characterSize * 0.1, y: characterSize * 0.58))
        path.addLine(to: CGPoint(x: characterSize * 0.3, y: characterSize * 0.76))
        path.addLine(to: CGPoint(x: characterSize * 0.3, y: characterSize * 0.45))
        path.closeSubpath()
        crown.path = path
        crown.fillColor = color
        crown.strokeColor = ink
        crown.lineWidth = 2
        accessoryLayer.addChild(crown)
    }

    private func addIsaacTears() {
        for x in [-characterSize * 0.155, characterSize * 0.155] {
            let tear = SKShapeNode()
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x, y: characterSize * 0.08))
            path.addCurve(
                to: CGPoint(x: x * 1.12, y: -characterSize * 0.3),
                control1: CGPoint(x: x * 0.9, y: -characterSize * 0.02),
                control2: CGPoint(x: x * 1.2, y: -characterSize * 0.18)
            )
            tear.path = path
            tear.strokeColor = SKColor(red: 0.22, green: 0.65, blue: 0.92, alpha: 0.9)
            tear.lineWidth = 4
            tear.lineCap = .round
            accessoryLayer.addChild(tear)
        }
        let mouth = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.18,
                                                   height: characterSize * 0.12))
        mouth.fillColor = ink
        mouth.strokeColor = .clear
        mouth.position.y = -characterSize * 0.1
        accessoryLayer.addChild(mouth)
    }

    private func addFedoraAndGlove() {
        let crown = SKShapeNode(rectOf: CGSize(width: characterSize * 0.62,
                                               height: characterSize * 0.27), cornerRadius: 5)
        crown.fillColor = .black
        crown.strokeColor = ink
        crown.lineWidth = 2
        crown.position = CGPoint(x: -characterSize * 0.08, y: characterSize * 0.56)
        crown.zRotation = -0.12
        accessoryLayer.addChild(crown)
        let brim = SKShapeNode(rectOf: CGSize(width: characterSize * 0.92,
                                              height: characterSize * 0.08), cornerRadius: 3)
        brim.fillColor = .black
        brim.strokeColor = ink
        brim.lineWidth = 1.5
        brim.position.y = characterSize * 0.44
        brim.zRotation = -0.12
        accessoryLayer.addChild(brim)
        let glove = SKShapeNode(circleOfRadius: characterSize * 0.12)
        glove.fillColor = .white
        glove.strokeColor = ink
        glove.lineWidth = 2
        glove.position = CGPoint(x: characterSize * 0.61, y: characterSize * 0.03)
        accessoryLayer.addChild(glove)
    }

    private func addStardustFlash() {
        let flash = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -characterSize * 0.3, y: characterSize * 0.43))
        path.addLine(to: CGPoint(x: -characterSize * 0.05, y: characterSize * 0.14))
        path.addLine(to: CGPoint(x: -characterSize * 0.18, y: characterSize * 0.11))
        path.addLine(to: CGPoint(x: characterSize * 0.08, y: -characterSize * 0.2))
        flash.path = path
        flash.strokeColor = SKColor(red: 0.94, green: 0.16, blue: 0.22, alpha: 1)
        flash.lineWidth = 5
        flash.lineCap = .round
        flash.lineJoin = .round
        accessoryLayer.addChild(flash)
        let halo = SKShapeNode(circleOfRadius: characterSize * 0.68)
        halo.fillColor = .clear
        halo.strokeColor = .systemBlue.withAlphaComponent(0.22)
        halo.lineWidth = 3
        auraLayer.addChild(halo)
    }

    private func addSleuthKit() {
        let cap = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.82,
                                                height: characterSize * 0.3))
        cap.fillColor = SKColor(red: 0.45, green: 0.3, blue: 0.16, alpha: 1)
        cap.strokeColor = ink
        cap.lineWidth = 2
        cap.position.y = characterSize * 0.52
        accessoryLayer.addChild(cap)
        let lens = SKShapeNode(circleOfRadius: characterSize * 0.18)
        lens.fillColor = SKColor(red: 0.65, green: 0.9, blue: 1, alpha: 0.18)
        lens.strokeColor = ink
        lens.lineWidth = 3
        lens.position = CGPoint(x: characterSize * 0.5, y: -characterSize * 0.02)
        accessoryLayer.addChild(lens)
        let handle = SKShapeNode(rectOf: CGSize(width: 4, height: characterSize * 0.38), cornerRadius: 2)
        handle.fillColor = ink
        handle.strokeColor = .clear
        handle.position = CGPoint(x: characterSize * 0.64, y: -characterSize * 0.25)
        handle.zRotation = -0.55
        accessoryLayer.addChild(handle)
    }

    private func addPlumberGear() {
        let cap = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.78,
                                                height: characterSize * 0.28))
        cap.fillColor = .systemRed
        cap.strokeColor = ink
        cap.lineWidth = 2
        cap.position.y = characterSize * 0.54
        accessoryLayer.addChild(cap)
        let badge = SKShapeNode(circleOfRadius: characterSize * 0.09)
        badge.fillColor = .white
        badge.strokeColor = ink
        badge.lineWidth = 1.3
        badge.position.y = characterSize * 0.57
        accessoryLayer.addChild(badge)
        let star = SKLabelNode(text: "★")
        star.fontSize = characterSize * 0.12
        star.fontColor = .systemRed
        star.verticalAlignmentMode = .center
        star.position.y = characterSize * 0.57
        accessoryLayer.addChild(star)
        for direction in [-1.0, 1.0] as [CGFloat] {
            let moustache = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.26,
                                                          height: characterSize * 0.12))
            moustache.fillColor = ink
            moustache.strokeColor = .clear
            moustache.position = CGPoint(x: direction * characterSize * 0.1,
                                         y: -characterSize * 0.08)
            moustache.zRotation = direction * -0.18
            accessoryLayer.addChild(moustache)
        }
        let mouth = SKShapeNode(ellipseOf: CGSize(width: characterSize * 0.12,
                                                   height: characterSize * 0.06))
        mouth.fillColor = ink
        mouth.strokeColor = .clear
        mouth.position.y = -characterSize * 0.17
        accessoryLayer.addChild(mouth)
    }

    private func addSpeedsterSpikes() {
        for index in 0..<5 {
            let spike = SKShapeNode()
            let path = CGMutablePath()
            let y = characterSize * (0.42 - CGFloat(index) * 0.19)
            path.move(to: CGPoint(x: -characterSize * 0.32, y: y))
            path.addLine(to: CGPoint(x: -characterSize * (0.72 + CGFloat(index) * 0.06),
                                     y: y + characterSize * 0.13))
            path.addLine(to: CGPoint(x: -characterSize * 0.38,
                                     y: y - characterSize * 0.12))
            path.closeSubpath()
            spike.path = path
            spike.fillColor = SKColor(red: 0.04, green: 0.28, blue: 0.75, alpha: 1)
            spike.strokeColor = ink
            spike.lineWidth = 1.5
            accessoryLayer.addChild(spike)
        }
        for foot in [leftFoot, rightFoot] {
            foot.fillColor = .systemRed
        }
    }

    private func addAura(colors: [SKColor]) {
        for (index, color) in colors.enumerated() {
            let ring = SKShapeNode(circleOfRadius: characterSize * (0.68 + CGFloat(index) * 0.1))
            ring.fillColor = .clear
            ring.strokeColor = color.withAlphaComponent(0.28)
            ring.lineWidth = 3
            ring.zRotation = CGFloat(index) * 0.6
            auraLayer.addChild(ring)
            ring.run(.repeatForever(.group([
                .rotate(byAngle: index.isMultiple(of: 2) ? .pi * 2 : -.pi * 2,
                        duration: 2.5 + Double(index) * 0.5),
                .sequence([.fadeAlpha(to: 0.25, duration: 0.65),
                           .fadeAlpha(to: 0.8, duration: 0.65)]),
            ])))
        }
    }

    private func addOrbitingStars() {
        for index in 0..<3 {
            let orbit = SKNode()
            let star = SKShapeNode(circleOfRadius: 2.5)
            star.fillColor = .white
            star.strokeColor = .clear
            star.position.x = characterSize * (0.72 + CGFloat(index) * 0.08)
            orbit.addChild(star)
            orbit.zRotation = CGFloat(index) * .pi * 2 / 3
            accessoryLayer.addChild(orbit)
            orbit.run(.repeatForever(.rotate(byAngle: .pi * 2,
                                             duration: 1.8 + Double(index) * 0.35)))
        }
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
        body.fillColor = activeBodyColor
        removeAction(forKey: "death")
        removeAction(forKey: "squash")
        setScale(1)
        zRotation = 0
        alpha = 1
    }

    func flashDead() {
        body.fillColor = SKColor(red: 0.91, green: 0.3, blue: 0.2, alpha: 1)
    }
}
