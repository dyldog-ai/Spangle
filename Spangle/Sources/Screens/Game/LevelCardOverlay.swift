import SwiftUI

/// A themed storybook card used before a level begins.
struct LevelCardOverlay: View {
    let emoji: String
    let eyebrow: String
    let title: String
    let subtitle: String
    let button: String
    let action: () -> Void
    var secondary: (label: String, action: () -> Void)? = nil

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.68).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 13) {
                    Text(emoji)
                        .font(.system(size: 56))
                        .frame(width: 88, height: 88)
                        .background(Color.storybookCream, in: Circle())
                        .overlay(Circle().stroke(Color.storybookInk.opacity(0.5), lineWidth: 2))
                        .shadow(color: .storybookInk.opacity(0.2), radius: 0, y: 4)
                    Text(eyebrow.uppercased())
                        .font(.caption.weight(.black))
                        .tracking(2)
                        .foregroundStyle(Color.storybookRed)
                    Text(title)
                        .font(.system(size: 37, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                    Text(subtitle)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(Color.storybookInk.opacity(0.68))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        Button(button, action: action)
                            .buttonStyle(StorybookPrimaryButtonStyle())
                            .keyboardShortcut(.defaultAction)
                        if let secondary {
                            Button(secondary.label, action: secondary.action)
                                .buttonStyle(StorybookSecondaryButtonStyle())
                        }
                    }
                    .padding(.top, 5)
                }
                .frame(maxWidth: 520)
            }
            .padding(22)
        }
    }
}
