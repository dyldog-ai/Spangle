import SwiftUI

struct GameOverOverlay: View {
    let reason: String
    let hasCheckpoint: Bool
    let retryCheckpoint: () -> Void
    let retryStart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("¡Ay!")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                Text(reason)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                if hasCheckpoint {
                    Button("Retry checkpoint", action: retryCheckpoint)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    Button("Restart level", action: retryStart)
                } else {
                    Button("Try again", action: retryStart)
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                }
                Button("Menu", action: onMenu)
            }
            .font(.title3.bold())
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }
}
