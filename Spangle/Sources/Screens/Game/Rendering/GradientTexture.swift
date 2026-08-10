import CoreGraphics
import SpriteKit

/// Small procedural textures that give the game a softly printed storybook
/// finish without shipping resolution-specific raster backgrounds.
enum GradientTexture {
    static func vertical(size: CGSize, top: SKColor, bottom: SKColor) -> SKTexture {
        let width = max(8, Int(size.width))
        let height = max(8, Int(size.height))
        guard let context = makeContext(width: width, height: height) else { return SKTexture() }
        let space = CGColorSpaceCreateDeviceRGB()
        let middle = bottom.lighter(0.1)
        let colors = [bottom.cgColor, middle.cgColor, top.cgColor] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: space,
            colors: colors,
            locations: [0, 0.55, 1]
        ) else { return SKTexture() }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: CGFloat(height)),
            options: []
        )

        addPaperGrain(to: context, width: width, height: height, opacity: 0.035)
        addEdgeWash(to: context, width: width, height: height)
        guard let image = context.makeImage() else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }

    static func paper(size: CGSize, color: SKColor, seed: UInt64) -> SKTexture {
        let width = max(8, Int(size.width))
        let height = max(8, Int(size.height))
        guard let context = makeContext(width: width, height: height) else { return SKTexture() }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        var state = seed == 0 ? 0xA0761D6478BD642F : seed
        for _ in 0..<(width * height / 18) {
            state = state &* 6_364_136_223_846_793_005 &+ 1
            let x = Int(state % UInt64(width))
            state = state &* 6_364_136_223_846_793_005 &+ 1
            let y = Int(state % UInt64(height))
            let light = (state & 1) == 0
            context.setFillColor(SKColor(white: light ? 1 : 0, alpha: 0.055).cgColor)
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
        guard let image = context.makeImage() else { return SKTexture() }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }

    static func vignette(size: CGSize) -> SKTexture {
        let width = max(8, Int(size.width))
        let height = max(8, Int(size.height))
        guard let context = makeContext(width: width, height: height) else { return SKTexture() }
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [
            SKColor.clear.cgColor,
            SKColor(red: 0.11, green: 0.06, blue: 0.04, alpha: 0.04).cgColor,
            SKColor(red: 0.08, green: 0.035, blue: 0.02, alpha: 0.22).cgColor,
        ] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: space,
            colors: colors,
            locations: [0, 0.72, 1]
        ) else { return SKTexture() }
        let center = CGPoint(x: CGFloat(width) / 2, y: CGFloat(height) / 2)
        context.drawRadialGradient(
            gradient,
            startCenter: center,
            startRadius: 0,
            endCenter: center,
            endRadius: hypot(CGFloat(width), CGFloat(height)) * 0.58,
            options: [.drawsAfterEndLocation]
        )
        guard let image = context.makeImage() else { return SKTexture() }
        return SKTexture(cgImage: image)
    }

    private static func makeContext(width: Int, height: Int) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    private static func addPaperGrain(
        to context: CGContext,
        width: Int,
        height: Int,
        opacity: CGFloat
    ) {
        var state: UInt64 = 0xE7037ED1A0B428DB
        for _ in 0..<(width * height / 32) {
            state = state &* 2_862_933_555_777_941_757 &+ 3_037_000_493
            let x = Int(state % UInt64(width))
            state ^= state >> 17
            let y = Int(state % UInt64(height))
            context.setFillColor(SKColor(white: state & 1 == 0 ? 1 : 0, alpha: opacity).cgColor)
            context.fill(CGRect(x: x, y: y, width: 1, height: 1))
        }
    }

    private static func addEdgeWash(to context: CGContext, width: Int, height: Int) {
        let space = CGColorSpaceCreateDeviceRGB()
        let colors = [SKColor.clear.cgColor, SKColor(white: 1, alpha: 0.075).cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else {
            return
        }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: CGFloat(width), y: CGFloat(height)),
            options: []
        )
    }
}
