import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Lightweight procedural tones and haptics; no bundled audio assets are required.
@MainActor
final class GameFeedback {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private weak var settings: GameSettings?

    init(settings: GameSettings) {
        self.settings = settings
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        try? engine.start()
    }

    func jump() { play(frequency: 330, duration: 0.05, amplitude: 0.08) }
    func pickup() { play(frequency: 740, duration: 0.09, amplitude: 0.13); haptic(.light) }
    func star() { play(frequency: 980, duration: 0.14, amplitude: 0.16); haptic(.medium) }
    func checkpoint() { play(frequency: 520, duration: 0.18, amplitude: 0.13); haptic(.medium) }
    func correct() { play(frequency: 660, duration: 0.16, amplitude: 0.14); haptic(.light) }
    func damage() { play(frequency: 120, duration: 0.2, amplitude: 0.18); haptic(.heavy) }
    func complete() { play(frequency: 880, duration: 0.35, amplitude: 0.14); haptic(.medium) }

    private func play(frequency: Double, duration: Double, amplitude: Float) {
        guard settings?.soundEnabled == true else { return }
        if !engine.isRunning { try? engine.start() }
        let sampleRate = 44_100.0
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frameCount
        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let envelope = Float(sin(.pi * progress))
            samples[frame] = sin(Float(frame) * Float(2 * Double.pi * frequency / sampleRate))
                * amplitude * envelope
        }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }

    private enum HapticWeight { case light, medium, heavy }

    private func haptic(_ weight: HapticWeight) {
        guard settings?.hapticsEnabled == true else { return }
        #if os(iOS)
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch weight {
        case .light: style = .light
        case .medium: style = .medium
        case .heavy: style = .heavy
        }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
        #endif
    }
}
