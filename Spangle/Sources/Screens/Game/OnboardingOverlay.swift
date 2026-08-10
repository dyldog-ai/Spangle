import SwiftUI

struct OnboardingOverlay: View {
    let onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.76).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 16) {
                    Text("¡Hola!")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                    Text("RUN · JUMP · LEARN")
                        .font(.caption.weight(.black))
                        .tracking(2.2)
                        .foregroundStyle(Color.storybookRed)
                    VStack(alignment: .leading, spacing: 11) {
                        instruction("hand.tap.fill", "Tap or press Space. Hold longer to jump higher.")
                        instruction("text.book.closed.fill", "Collect word coins, then translate them at gates.")
                        instruction("star.fill", "Find three optional stars for a perfect rating.")
                        instruction("shield.fill", "Shields absorb a hit. Checkpoints save your run.")
                    }
                    .frame(maxWidth: 500)
                    Button("Start playing", action: onFinish)
                        .buttonStyle(StorybookPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                }
            }
            .padding(22)
        }
    }

    private func instruction(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.storybookBlue, in: Circle())
            Text(text)
                .font(.body.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
