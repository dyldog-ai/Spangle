import SwiftUI

/// Bidirectional translation question used by gates, final quizzes, and review.
struct QuizOverlay: View {
    let question: QuizQuestion
    let onPick: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(question.heading)
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(directionLabel)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Text(question.prompt)
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.65)
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        Button { onPick(option) } label: {
                            Text(option)
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .padding(.horizontal, 8)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .frame(maxWidth: 520)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
        .accessibilityElement(children: .contain)
    }

    private let columns = [GridItem(.adaptive(minimum: 180), spacing: 12)]

    private var directionLabel: String {
        question.direction == .spanishToEnglish
            ? "SPANISH → ENGLISH"
            : "ENGLISH → SPANISH"
    }
}
