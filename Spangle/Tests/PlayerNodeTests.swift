import SpriteKit
import Testing
@testable import Spangle

struct PlayerNodeTests {
    @Test
    func shopPortraitUsesTheGameplayPlayerNode() throws {
        let design = try #require(CharacterCatalog.all.first { $0.style == .isaac })
        let portrait = CharacterPortraitScene(design: design)
        let player = try #require(portrait.childNode(withName: "portraitPlayer"))

        #expect(player is PlayerNode)
        #expect(player.childNode(withName: "//mouth") != nil)
    }

    @Test
    func mouthRendersAboveClothingAndBellyDetails() throws {
        let player = PlayerNode(size: 46)
        let mouth = try #require(player.childNode(withName: "//mouth"))
        let scarf = try #require(player.childNode(withName: "//scarf"))
        let belly = try #require(player.childNode(withName: "//belly"))

        #expect(mouth.zPosition > scarf.zPosition)
        #expect(mouth.zPosition > belly.zPosition)
    }

    @Test
    func restoringPlayerCancelsAnInFlightDeathAnimation() {
        let player = PlayerNode(size: 46)
        player.run(.scale(to: 0, duration: 1), withKey: "death")
        player.setScale(0.4)

        player.setAlive()

        #expect(player.action(forKey: "death") == nil)
        #expect(player.xScale == 1)
        #expect(player.yScale == 1)
        #expect(player.alpha == 1)
    }
}
