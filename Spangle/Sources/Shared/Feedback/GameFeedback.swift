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

        // Scheduled buffers must exactly match the player's negotiated output
        // format. A hard-coded mono buffer crashes on stereo device routes.
        let format = player.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        guard sampleRate > 0, channelCount > 0 else { return }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else { return }
        buffer.frameLength = frameCount

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let envelope = Float(sin(.pi * progress))
            let sample = sin(Float(frame) * Float(2 * Double.pi * frequency / sampleRate))
                * amplitude * envelope
            for channel in 0..<channelCount {
                channels[channel][frame] = sample
            }
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
