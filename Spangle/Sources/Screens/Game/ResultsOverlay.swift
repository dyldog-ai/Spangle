import SwiftUI

struct ResultsOverlay: View {
    let summary: RunSummary
    let nextTheme: Theme?
    let onContinue: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.74).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 13) {
                    HStack(spacing: 5) {
                        ForEach(0..<Level.challengeStarCount, id: \.self) { index in
                            Image(systemName: index < summary.stars ? "star.fill" : "star")
                                .font(.system(size: 27, weight: .bold))
                                .foregroundStyle(index < summary.stars ? Color.storybookGold : Color.storybookInk.opacity(0.25))
                                .rotationEffect(.degrees(index == 1 ? 0 : (index == 0 ? -8 : 8)))
                        }
                    }
                    Text("RUN COMPLETE")
                        .font(.caption.weight(.black))
                        .tracking(2)
                        .foregroundStyle(Color.storybookRed)
                    Text(summary.title)
                        .font(.system(size: 33, weight: .black, design: .rounded))
                    HStack(spacing: 12) {
                        result("Score", summary.score.formatted(), icon: "seal.fill")
                        result("Stars", "\(summary.stars)/3", icon: "star.fill")
                        result("Accuracy", "\(summary.accuracy)%", icon: "checkmark.circle.fill")
                        result("Time", durationText, icon: "clock.fill")
                    }
                    Text("\(summary.wordsCollected) word coins · \(summary.correctAnswers) correct")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.storybookInk.opacity(0.62))
                    if summary.usedCheckpoint {
                        Label("Recovered from a checkpoint", systemImage: "flag.checkered")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.storybookInk.opacity(0.58))
                    }
                    Button(nextTheme == nil ? "Back to menu" : "Next level", action: onContinue)
                        .buttonStyle(StorybookPrimaryButtonStyle())
                        .keyboardShortcut(.defaultAction)
                    if nextTheme != nil {
                        Button("Menu", action: onMenu)
                            .buttonStyle(StorybookSecondaryButtonStyle())
                    }
                }
            }
            .padding(22)
        }
    }

    private func result(_ label: String, _ value: String, icon: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.storybookBlue)
            Text(value).font(.headline.bold()).monospacedDigit()
            Text(label).font(.caption2).foregroundStyle(Color.storybookInk.opacity(0.55))
        }
        .frame(minWidth: 74)
        .padding(.vertical, 8)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.48), in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .combine)
    }

    private var durationText: String {
        let seconds = max(0, Int(summary.duration.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
