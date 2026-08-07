import CoreGraphics
import SpriteKit

/// Cross-platform (iOS + macOS) generation of a vertical gradient texture,
/// used for skies. Drawn once per level with CoreGraphics.
enum GradientTexture {
    static func vertical(size: CGSize, top: SKColor, bottom: SKColor) -> SKTexture {
        let w = max(2, Int(size.width))
        let h = max(2, Int(size.height))
        let space = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: space,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return SKTexture()
        }
        let colors = [bottom.cgColor, top.cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors,
                                        locations: [0, 1]) else { return SKTexture() }
        ctx.drawLinearGradient(gradient,
                               start: CGPoint(x: 0, y: 0),
                               end: CGPoint(x: 0, y: CGFloat(h)),
                               options: [])
        guard let image = ctx.makeImage() else { return SKTexture() }
        return SKTexture(cgImage: image)
    }
}
