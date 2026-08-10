import SwiftUI

/// Warm Mediterranean landscape used behind menus and modal cards.
struct StorybookBackdrop: View {
    var dimmed = false

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [.storybookBlue, Color(red: 0.52, green: 0.79, blue: 0.82), .storybookCream],
                    startPoint: .top,
                    endPoint: .bottom
                )
                sun(size: proxy.size)
                paintedHills(size: proxy.size)
                tileBorder(size: proxy.size)
                paperGrain
                if dimmed { Color.storybookInk.opacity(0.68) }
            }
        }
        .ignoresSafeArea()
    }

    private func sun(size: CGSize) -> some View {
        Circle()
            .fill(Color.storybookCream)
            .overlay(Circle().stroke(.white.opacity(0.45), lineWidth: 3))
            .shadow(color: .storybookCream.opacity(0.45), radius: 28)
            .frame(width: min(size.width, size.height) * 0.19)
            .position(x: size.width * 0.82, y: size.height * 0.18)
    }

    private func paintedHills(size: CGSize) -> some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.storybookGreen.opacity(0.5))
                .frame(width: size.width * 1.35, height: size.height * 0.57)
                .offset(x: -size.width * 0.31, y: size.height * 0.3)
            Ellipse()
                .fill(Color(red: 0.28, green: 0.62, blue: 0.35))
                .frame(width: size.width * 1.45, height: size.height * 0.54)
                .offset(x: size.width * 0.3, y: size.height * 0.36)
        }
        .frame(width: size.width, height: size.height)
        .clipped()
    }

    private func tileBorder(size: CGSize) -> some View {
        HStack(spacing: 7) {
            ForEach(0..<max(12, Int(size.width / 28)), id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index.isMultiple(of: 2) ? Color.storybookRed : Color.storybookGold)
                    .frame(width: 13, height: 13)
                    .rotationEffect(.degrees(45))
                    .overlay(
                        Circle()
                            .fill(Color.storybookPaper.opacity(0.75))
                            .frame(width: 4, height: 4)
                    )
            }
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 9)
        .opacity(0.84)
    }

    private var paperGrain: some View {
        Canvas { context, size in
            for index in 0..<180 {
                let x = CGFloat((index * 79) % 997) / 997 * size.width
                let y = CGFloat((index * 47) % 991) / 991 * size.height
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)),
                    with: .color(index.isMultiple(of: 2) ? .white.opacity(0.08) : .black.opacity(0.035))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
