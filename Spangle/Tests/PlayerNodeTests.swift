import SpriteKit
import Testing
@testable import Spangle

struct PlayerNodeTests {
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
