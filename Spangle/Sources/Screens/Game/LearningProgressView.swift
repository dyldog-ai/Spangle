import SwiftUI

struct LearningProgressView: View {
    let store: LearningProgressStore
    let onReview: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    Text("🧠").font(.system(size: 58))
                    Text("Learning Progress")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                    HStack(spacing: 12) {
                        metric("Mastered", store.masteredCount, "checkmark.seal.fill")
                        metric("Learning", store.learningCount, "book.fill")
                        metric("Due", store.dueCount, "clock.fill")
                    }
                    VStack(spacing: 6) {
                        Text("\(Int((store.accuracy * 100).rounded()))%")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("accuracy across \(store.totalAnswers) answers")
                            .foregroundStyle(.secondary)
                    }
                    Button("Review weakest words") {
                        dismiss()
                        onReview()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.learningCount == 0 && store.totalAnswers == 0)
                }
                .padding(28)
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 500, minHeight: 380)
    }

    private func metric(_ title: String, _ value: Int, _ icon: String) -> some View {
        VStack(spacing: 7) {
            Image(systemName: icon).font(.title2)
            Text(value.formatted()).font(.title.bold()).monospacedDigit()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}
