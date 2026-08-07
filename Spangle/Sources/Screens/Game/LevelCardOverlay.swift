import SwiftUI

/// A themed card used for the level intro and level-complete screens.
struct LevelCardOverlay: View {
    let emoji: String
    let eyebrow: String   // e.g. "Nivel 3" or "¡Nivel completado!"
    let title: String     // Spanish theme name
    let subtitle: String  // English theme name / message
    let button: String
    let action: () -> Void
    var secondary: (label: String, action: () -> Void)? = nil

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 12) {
                Text(emoji).font(.system(size: 64))
                Text(eyebrow)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(button, action: action)
                    .font(.title3.bold())
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 8)
                if let secondary {
                    Button(secondary.label, action: secondary.action)
                        .font(.body)
                }
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }
}
