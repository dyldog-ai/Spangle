import SwiftUI

/// Full-screen parchment panel with a single primary action.
struct MessageOverlay: View {
    let title: String
    let message: String
    let button: String
    let action: () -> Void
    var secondary: (label: String, action: () -> Void)? = nil

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.7).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(Color.storybookGold)
                    Text(title)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(message)
                        .font(.title3.weight(.medium))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.storybookInk.opacity(0.68))
                    Button(button, action: action)
                        .buttonStyle(StorybookPrimaryButtonStyle())
                        .padding(.top, 3)
                    if let secondary {
                        Button(secondary.label, action: secondary.action)
                            .buttonStyle(StorybookSecondaryButtonStyle())
                    }
                }
                .frame(maxWidth: 520)
            }
            .padding(22)
        }
    }
}
