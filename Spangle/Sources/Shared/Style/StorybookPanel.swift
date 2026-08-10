import SwiftUI

/// Parchment card with a hand-bound, release-level modal treatment.
struct StorybookPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .foregroundStyle(Color.storybookInk)
            .padding(30)
            .background {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.storybookPaper)
                    .shadow(color: .storybookInk.opacity(0.34), radius: 0, y: 7)
                    .shadow(color: .black.opacity(0.24), radius: 22, y: 14)
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.75), lineWidth: 2)
                            .padding(4)
                    }
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.storybookRed, .storybookGold, .storybookBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 7)
                            .padding(.horizontal, 34)
                            .offset(y: -3)
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.storybookInk.opacity(0.5), lineWidth: 2)
            }
    }
}
