import SwiftUI

/// Translation gate: pick the English meaning of the collected Spanish word.
struct QuizOverlay: View {
    let word: VocabWord
    let options: [String]
    let onPick: (String) -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("What does this mean?")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text(word.spanish)
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                ForEach(options, id: \.self) { option in
                    Button { onPick(option) } label: {
                        Text(option)
                            .font(.title3.bold())
                            .frame(maxWidth: 320)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding()
        }
    }
}
