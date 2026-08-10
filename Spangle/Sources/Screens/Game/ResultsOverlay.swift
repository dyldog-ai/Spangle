import SwiftUI

struct ResultsOverlay: View {
    let summary: RunSummary
    let nextTheme: Theme?
    let onContinue: () -> Void
    let onMenu: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.66).ignoresSafeArea()
            VStack(spacing: 14) {
                Text(summary.stars == Level.challengeStarCount ? "🌟" : "🎉")
                    .font(.system(size: 54))
                Text("Run complete")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(summary.title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                HStack(spacing: 22) {
                    result("Score", summary.score.formatted())
                    result("Stars", "\(summary.stars)/3")
                    result("Accuracy", "\(summary.accuracy)%")
                    result("Time", durationText)
                }
                .padding(.vertical, 8)
                Text("\(summary.wordsCollected) word coins · \(summary.correctAnswers) correct")
                    .foregroundStyle(.secondary)
                if summary.usedCheckpoint {
                    Label("Recovered from a checkpoint", systemImage: "flag.checkered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Button(nextTheme == nil ? "Back to menu" : "Next level", action: onContinue)
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                if nextTheme != nil {
                    Button("Menu", action: onMenu)
                }
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }

    private func result(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.title3.bold()).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var durationText: String {
        let seconds = max(0, Int(summary.duration.rounded()))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
