import AVFoundation

/// Abstraction for audio cues, enabling dependency injection in tests.
protocol AudioPlayer {
    func playWorkStart()
    func playWorkEnd()
    func playRestStart()
    func playSetRestStart()
    func playCountdownBeep()
    func playComplete()
}

/// Synthesises pitched tones using AVAudioEngine so every cue has a distinct,
/// controllable sound. No system-sound IDs needed.
///
/// Tone design:
///   work start  – Low (440 Hz) → High (880 Hz)   ascending  = "go"
///   work end    – High (880 Hz) → Low (440 Hz)   descending = "stop"
///   rest start  – single mid tone (660 Hz)
///   set rest    – three-step ascending chime
///   countdown   – short sharp high beep
///   complete    – four-note ascending arpeggio
class AudioManager: AudioPlayer {

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44100

    init() {
        // Mix with whatever audio the user is already playing (e.g. music).
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        engine.attach(player)
        engine.connect(
            player,
            to: engine.mainMixerNode,
            format: AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        )
        try? engine.start()
    }

    // MARK: - AudioPlayer

    func playWorkStart()    { play(tones: [440, 880]) }                    // Low → High
    func playWorkEnd()      { play(tones: [880, 440]) }                    // High → Low
    func playRestStart()    { play(tones: [660], duration: 0.15) }
    func playSetRestStart() { play(tones: [440, 660, 880], duration: 0.12, gap: 0.04) }
    func playCountdownBeep(){ play(tones: [880], duration: 0.08) }
    func playComplete()     { play(tones: [440, 554, 659, 880], duration: 0.12, gap: 0.03) }

    // MARK: - Private

    private func play(tones: [Double],
                      duration: Double = 0.15,
                      gap: Double = 0.06,
                      amplitude: Float = 0.5) {
        if !engine.isRunning { try? engine.start() }
        let buffer = makeBuffer(tones: tones, duration: duration, gap: gap, amplitude: amplitude)
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }

    /// Builds a single PCM buffer containing each tone followed by a silent gap.
    /// An 8 ms linear ramp is applied at the start and end of every tone to
    /// eliminate clicks.
    private func makeBuffer(tones: [Double],
                            duration: Double,
                            gap: Double,
                            amplitude: Float) -> AVAudioPCMBuffer {
        let format     = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let toneFrames = Int(sampleRate * duration)
        let gapFrames  = Int(sampleRate * gap)
        let total      = AVAudioFrameCount(tones.count * (toneFrames + gapFrames))
        let buffer     = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: total)!
        buffer.frameLength = total

        let out  = buffer.floatChannelData![0]
        let ramp = max(1, Int(sampleRate * 0.008)) // 8 ms fade in/out
        var i    = 0

        for freq in tones {
            for t in 0..<toneFrames {
                let phase  = 2.0 * Double.pi * freq * Double(t) / sampleRate
                let signal = Float(sin(phase)) * amplitude
                let env: Float
                if t < ramp {
                    env = Float(t) / Float(ramp)
                } else if t >= toneFrames - ramp {
                    env = Float(toneFrames - t) / Float(ramp)
                } else {
                    env = 1.0
                }
                out[i] = signal * env
                i += 1
            }
            for _ in 0..<gapFrames { out[i] = 0; i += 1 }
        }
        return buffer
    }
}
