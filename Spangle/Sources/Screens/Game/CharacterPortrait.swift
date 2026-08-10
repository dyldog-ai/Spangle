import SpriteKit
import SwiftUI

/// Shop preview rendered by the same SpriteKit node used during gameplay.
struct CharacterPortrait: View {
    let design: CharacterDesign

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.storybookPaper.opacity(0.48))
                .overlay {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.storybookInk.opacity(0.24), lineWidth: 2)
                }
            SpriteView(
                scene: CharacterPortraitScene(design: design),
                options: [.allowsTransparency]
            )
            .accessibilityHidden(true)
        }
        .frame(width: 120, height: 120)
        .accessibilityHidden(true)
    }
}

final class CharacterPortraitScene: SKScene {
    init(design: CharacterDesign) {
        super.init(size: CGSize(width: 120, height: 120))
        scaleMode = .aspectFit
        backgroundColor = .clear

        let player = PlayerNode(size: 55)
        player.name = "portraitPlayer"
        player.position = CGPoint(x: size.width / 2, y: 57)
        player.apply(design: design)
        addChild(player)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
