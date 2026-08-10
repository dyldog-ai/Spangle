import SwiftUI

struct OnboardingOverlay: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("¡Hola! 👋")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                Text("Run, jump, and learn")
                    .font(.title2.bold())
                VStack(alignment: .leading, spacing: 12) {
                    instruction("hand.tap.fill", "Tap or press Space. Hold longer to jump higher.")
                    instruction("text.book.closed.fill", "Collect word coins, then translate them at ? gates.")
                    instruction("star.fill", "Find three optional stars for a perfect rating.")
                    instruction("shield.fill", "Shields absorb a hit. Checkpoints save the middle of a run.")
                }
                .frame(maxWidth: 480)
                Button("Start playing", action: onFinish)
                    .font(.title3.bold())
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }

    private func instruction(_ icon: String, _ text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
    }
}
