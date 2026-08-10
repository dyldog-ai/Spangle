import AVFoundation
#if os(iOS)
import UIKit
#endif

/// Original, procedurally rendered game audio with layered musical voices.
/// Sounds are generated in the negotiated device format, keeping the app small
/// while avoiding the placeholder quality of single oscillator beeps.
@MainActor
final class GameFeedback {
    private let engine = AVAudioEngine()
    private let players = (0..<6).map { _ in AVAudioPlayerNode() }
    private weak var settings: GameSettings?
    private var nextPlayer = 0

    init(settings: GameSettings) {
        self.settings = settings
        for player in players {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: nil)
        }
        engine.mainMixerNode.outputVolume = 0.82
        try? engine.start()
    }

    func jump() {
        play([
            Voice(start: 0, duration: 0.16, from: 250, to: 470, gain: 0.13, timbre: .rounded),
            Voice(start: 0.035, duration: 0.1, from: 520, to: 700, gain: 0.045, timbre: .air),
        ])
    }

    func pickup() {
        play([
            Voice(start: 0, duration: 0.18, from: 784, gain: 0.12, timbre: .bell),
            Voice(start: 0.055, duration: 0.2, from: 1_047, gain: 0.09, timbre: .bell),
            Voice(start: 0.01, duration: 0.1, from: 1_568, to: 1_700, gain: 0.035, timbre: .sparkle),
        ])
        haptic(.light)
    }

    func star() {
        play([
            Voice(start: 0, duration: 0.5, from: 523, gain: 0.11, timbre: .bell),
            Voice(start: 0.07, duration: 0.46, from: 659, gain: 0.1, timbre: .bell),
            Voice(start: 0.14, duration: 0.42, from: 784, gain: 0.1, timbre: .bell),
            Voice(start: 0.2, duration: 0.35, from: 1_047, gain: 0.055, timbre: .sparkle),
        ])
        haptic(.medium)
    }

    func checkpoint() {
        play([
            Voice(start: 0, duration: 0.28, from: 392, gain: 0.11, timbre: .pluck),
            Voice(start: 0.11, duration: 0.3, from: 523, gain: 0.11, timbre: .pluck),
            Voice(start: 0.22, duration: 0.38, from: 659, gain: 0.1, timbre: .bell),
        ])
        haptic(.medium)
    }

    func correct() {
        play([
            Voice(start: 0, duration: 0.24, from: 523, gain: 0.1, timbre: .rounded),
            Voice(start: 0.065, duration: 0.25, from: 659, gain: 0.1, timbre: .rounded),
            Voice(start: 0.13, duration: 0.3, from: 784, gain: 0.09, timbre: .bell),
        ])
        haptic(.light)
    }

    func damage() {
        play([
            Voice(start: 0, duration: 0.38, from: 210, to: 72, gain: 0.16, timbre: .rough),
            Voice(start: 0, duration: 0.2, from: 95, to: 55, gain: 0.08, timbre: .noise),
        ])
        haptic(.heavy)
    }

    func complete() {
        play([
            Voice(start: 0, duration: 0.32, from: 392, gain: 0.095, timbre: .pluck),
            Voice(start: 0.11, duration: 0.32, from: 523, gain: 0.095, timbre: .pluck),
            Voice(start: 0.22, duration: 0.34, from: 659, gain: 0.1, timbre: .pluck),
            Voice(start: 0.34, duration: 0.62, from: 784, gain: 0.12, timbre: .bell),
            Voice(start: 0.34, duration: 0.62, from: 988, gain: 0.07, timbre: .bell),
        ])
        haptic(.medium)
    }

    private func play(_ voices: [Voice]) {
        guard settings?.soundEnabled == true, !voices.isEmpty else { return }
        if !engine.isRunning { try? engine.start() }

        let player = players[nextPlayer]
        nextPlayer = (nextPlayer + 1) % players.count
        let format = player.outputFormat(forBus: 0)
        let sampleRate = format.sampleRate
        let channelCount = Int(format.channelCount)
        guard sampleRate > 0, channelCount > 0 else { return }

        let totalDuration = voices.map { $0.start + $0.duration }.max() ?? 0
        let frameCount = AVAudioFrameCount(ceil(sampleRate * totalDuration))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channels = buffer.floatChannelData else { return }
        buffer.frameLength = frameCount

        for voice in voices {
            render(voice, into: channels, frameCount: Int(frameCount),
                   channels: channelCount, sampleRate: sampleRate)
        }

        // A short voice pool allows rapid pickups to overlap naturally rather
        // than chopping off the preceding sound.
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }

    private func render(
        _ voice: Voice,
        into channels: UnsafePointer<UnsafeMutablePointer<Float>>,
        frameCount: Int,
        channels channelCount: Int,
        sampleRate: Double
    ) {
        let startFrame = Int(voice.start * sampleRate)
        let voiceFrames = max(1, Int(voice.duration * sampleRate))
        var phase = 0.0
        var noiseState: UInt64 = UInt64(startFrame + voiceFrames) &+ 0x9E3779B97F4A7C15

        for localFrame in 0..<voiceFrames {
            let frame = startFrame + localFrame
            guard frame < frameCount else { break }
            let progress = Double(localFrame) / Double(voiceFrames)
            let frequency = voice.from + (voice.to - voice.from) * progress
            phase += 2 * Double.pi * frequency / sampleRate
            let envelope = amplitudeEnvelope(progress: progress, timbre: voice.timbre)
            let sample = waveform(phase: phase, timbre: voice.timbre,
                                  progress: progress, noiseState: &noiseState)
                * Double(voice.gain) * envelope

            for channel in 0..<channelCount {
                let stereoShade = channelCount == 1 ? 1.0 : (channel == 0 ? 0.96 : 1.0)
                channels[channel][frame] += Float(sample * stereoShade)
            }
        }
    }

    private func amplitudeEnvelope(progress: Double, timbre: Timbre) -> Double {
        let attack = min(1, progress / (timbre == .rough ? 0.015 : 0.045))
        let release: Double
        switch timbre {
        case .bell, .sparkle, .pluck: release = pow(1 - progress, 2.2)
        case .noise: release = pow(1 - progress, 1.5)
        default: release = sin(.pi * progress)
        }
        return attack * max(0, release)
    }

    private func waveform(
        phase: Double,
        timbre: Timbre,
        progress: Double,
        noiseState: inout UInt64
    ) -> Double {
        switch timbre {
        case .rounded:
            return sin(phase) + 0.18 * sin(phase * 2) + 0.06 * sin(phase * 3)
        case .bell:
            return sin(phase) + 0.42 * sin(phase * 2.01) + 0.16 * sin(phase * 3.97)
        case .pluck:
            return sin(phase) + 0.24 * sin(phase * 2) * (1 - progress)
                + 0.1 * sin(phase * 4) * (1 - progress)
        case .sparkle:
            return sin(phase) + 0.3 * sin(phase * 2.7) + 0.12 * sin(phase * 5.03)
        case .air:
            return 0.75 * sin(phase) + 0.2 * randomSample(state: &noiseState)
        case .rough:
            return 0.65 * sin(phase) + 0.22 * sin(phase * 2)
                + 0.13 * (2 / .pi) * asin(sin(phase))
        case .noise:
            return randomSample(state: &noiseState)
        }
    }

    private func randomSample(state: inout UInt64) -> Double {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return Double(Int64(bitPattern: state) >> 40) / Double(1 << 23)
    }

    private struct Voice {
        let start: Double
        let duration: Double
        let from: Double
        let to: Double
        let gain: Float
        let timbre: Timbre

        init(start: Double, duration: Double, from: Double, to: Double? = nil,
             gain: Float, timbre: Timbre) {
            self.start = start
            self.duration = duration
            self.from = from
            self.to = to ?? from
            self.gain = gain
            self.timbre = timbre
        }
    }

    private enum Timbre { case rounded, bell, pluck, sparkle, air, rough, noise }
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
