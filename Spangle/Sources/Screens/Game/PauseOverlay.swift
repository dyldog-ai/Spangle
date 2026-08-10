import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onSettings: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.7).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 14) {
                    Image(systemName: "pause.circle.fill")
                        .font(.system(size: 46))
                        .foregroundStyle(Color.storybookBlue)
                    Text("Paused")
                        .font(.system(size: 39, weight: .black, design: .rounded))
                    HStack(spacing: 12) {
                        Button("Resume", action: onResume)
                            .buttonStyle(StorybookPrimaryButtonStyle())
                            .keyboardShortcut(.defaultAction)
                        Button("Settings", action: onSettings)
                            .buttonStyle(StorybookSecondaryButtonStyle())
                        Button("Menu", action: onMenu)
                            .buttonStyle(StorybookSecondaryButtonStyle())
                    }
                }
            }
        }
    }
}
