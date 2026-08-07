import SwiftUI

/// Full-screen game-over / victory panel with a single action button.
struct MessageOverlay: View {
    let title: String
    let message: String
    let button: String
    let action: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 40, weight: .heavy, design: .rounded))
                Text(message)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button(button, action: action)
                    .font(.title3.bold())
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }
}
