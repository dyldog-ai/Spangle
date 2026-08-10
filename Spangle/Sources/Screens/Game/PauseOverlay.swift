import SwiftUI

struct PauseOverlay: View {
    let onResume: () -> Void
    let onSettings: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.62).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("Paused")
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                Button("Resume", action: onResume)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                Button("Settings", action: onSettings)
                Button("Return to menu", action: onMenu)
            }
            .font(.title3.bold())
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        }
    }
}
