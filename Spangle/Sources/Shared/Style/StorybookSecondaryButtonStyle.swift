import SwiftUI

struct StorybookSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(Color.storybookInk)
            .padding(.horizontal, 18)
            .frame(minHeight: 44)
            .background(Color.white.opacity(configuration.isPressed ? 0.45 : 0.72), in: Capsule())
            .overlay(Capsule().stroke(Color.storybookInk.opacity(0.28), lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
