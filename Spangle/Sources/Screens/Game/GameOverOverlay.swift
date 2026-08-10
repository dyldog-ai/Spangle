import SwiftUI

struct GameOverOverlay: View {
    let reason: String
    let hasCheckpoint: Bool
    let retryCheckpoint: () -> Void
    let retryStart: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.72).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 14) {
                    Image(systemName: "heart.slash.fill")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color.storybookRed)
                    Text("¡Ay!")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                    Text(reason)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.storybookInk.opacity(0.66))
                    if hasCheckpoint {
                        Button("Retry checkpoint", action: retryCheckpoint)
                            .buttonStyle(StorybookPrimaryButtonStyle())
                            .keyboardShortcut(.defaultAction)
                        Button("Restart level", action: retryStart)
                            .buttonStyle(StorybookSecondaryButtonStyle())
                    } else {
                        Button("Try again", action: retryStart)
                            .buttonStyle(StorybookPrimaryButtonStyle())
                            .keyboardShortcut(.defaultAction)
                    }
                    Button("Menu", action: onMenu)
                        .buttonStyle(StorybookSecondaryButtonStyle())
                }
                .frame(maxWidth: 480)
            }
            .padding(22)
        }
    }
}
