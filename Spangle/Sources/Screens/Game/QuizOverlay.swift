import SwiftUI

/// Bidirectional translation question used by gates, final quizzes, and review.
struct QuizOverlay: View {
    let question: QuizQuestion
    let onPick: (String) -> Void

    var body: some View {
        ZStack {
            Color.storybookInk.opacity(0.72).ignoresSafeArea()
            StorybookPanel {
                VStack(spacing: 15) {
                    Label(question.heading.uppercased(), systemImage: "book.pages.fill")
                        .font(.caption.weight(.black))
                        .tracking(1.6)
                        .foregroundStyle(Color.storybookRed)
                    Text(directionLabel)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.storybookInk.opacity(0.55))
                    Text(question.prompt)
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.65)
                        .padding(.vertical, 2)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            Button { onPick(option) } label: {
                                Text(option)
                                    .font(.title3.weight(.bold))
                                    .frame(maxWidth: .infinity, minHeight: 50)
                                    .padding(.horizontal, 10)
                            }
                            .buttonStyle(StorybookSecondaryButtonStyle())
                        }
                    }
                    .frame(maxWidth: 550)
                }
            }
            .padding(22)
        }
        .accessibilityElement(children: .contain)
    }

    private let columns = [GridItem(.adaptive(minimum: 190), spacing: 12)]

    private var directionLabel: String {
        question.direction == .spanishToEnglish
            ? "SPANISH  →  ENGLISH"
            : "ENGLISH  →  SPANISH"
    }
}
