import SwiftUI

struct StorybookPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.heavy))
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .frame(minHeight: 50)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [.storybookRed, Color(red: 0.91, green: 0.31, blue: 0.16)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .storybookInk.opacity(0.32), radius: 0, y: 4)
            }
            .overlay(Capsule().stroke(.white.opacity(0.5), lineWidth: 2).padding(3))
            .overlay(Capsule().stroke(Color.storybookInk.opacity(0.7), lineWidth: 2))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
