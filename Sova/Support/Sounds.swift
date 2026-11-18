import AVFoundation

/// Tiny synthesized sounds: a soft blip, a two-note "done", a little
/// arpeggio for a finished day. They're made in code (no audio files),
/// play under the ambient category so the silent switch mutes them and
/// other audio keeps playing, and can be turned off in Settings.
@MainActor
enum Sounds {
    enum Effect: CaseIterable {
        /// A light blip for selections.
        case tick
        /// Something checked off: a rising two-note ding.
        case check
        /// Something unchecked: one soft low note.
        case uncheck
        /// A bubbly pop for things appearing.
        case pop
        /// The owl's soft "hoo-hoo".
        case owl
        /// A whole day or goal finished: a bright arpeggio.
        case celebrate
    }

    static var isEnabled: Bool {
        UserDefaults.standard.object(forKey: "soundsOn") as? Bool ?? true
    }

    static func play(_ effect: Effect) {
        guard isEnabled, prepare() else { return }
        let buffer = buffers[effect] ?? synthesize(effect)
        buffers[effect] = buffer
        let player = players[next]
        next = (next + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    // MARK: Engine

    private static let sampleRate = 44_100.0
    private static let engine = AVAudioEngine()
    private static let players = (0..<4).map { _ in AVAudioPlayerNode() }
    private static var next = 0
    private static var attached = false
    private static var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private static let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

    private static func prepare() -> Bool {
        if engine.isRunning { return true }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
            if !attached {
                for player in players {
                    engine.attach(player)
                    engine.connect(player, to: engine.mainMixerNode, format: format)
                }
                engine.mainMixerNode.outputVolume = 0.9
                attached = true
            }
            engine.prepare()
            try engine.start()
            return true
        } catch {
            return false
        }
    }

    // MARK: Synthesis

    /// One voice: a sine (plus a quiet octave for warmth) gliding from
    /// `from` to `to` Hz, with a quick attack and an exponential fade.
    private struct Note {
        var from: Double
        var to: Double? = nil
        var start: Double
        var length: Double
        var volume: Double = 0.22
    }

    private static func notes(for effect: Effect) -> [Note] {
        switch effect {
        case .tick:
            [Note(from: 1760, start: 0, length: 0.035, volume: 0.10)]
        case .check:
            [Note(from: 988, start: 0, length: 0.09, volume: 0.18),
             Note(from: 1480, start: 0.06, length: 0.16, volume: 0.16)]
        case .uncheck:
            [Note(from: 620, to: 520, start: 0, length: 0.08, volume: 0.12)]
        case .pop:
            [Note(from: 420, to: 980, start: 0, length: 0.07, volume: 0.13)]
        case .owl:
            [Note(from: 560, to: 500, start: 0, length: 0.13, volume: 0.12),
             Note(from: 500, to: 440, start: 0.15, length: 0.18, volume: 0.11)]
        case .celebrate:
            [1047.0, 1319, 1568, 2093].enumerated().map { i, f in
                Note(from: f, start: Double(i) * 0.075, length: 0.32, volume: 0.13)
            }
        }
    }

    private static func synthesize(_ effect: Effect) -> AVAudioPCMBuffer {
        let notes = notes(for: effect)
        let duration = (notes.map { $0.start + $0.length }.max() ?? 0.1) + 0.02
        let frames = AVAudioFrameCount(duration * sampleRate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        let out = buffer.floatChannelData![0]
        for i in 0..<Int(frames) { out[i] = 0 }

        for note in notes {
            let first = Int(note.start * sampleRate)
            let count = Int(note.length * sampleRate)
            var phase = 0.0
            for n in 0..<count where first + n < Int(frames) {
                let t = Double(n) / sampleRate
                let progress = Double(n) / Double(count)
                let freq = note.from + ((note.to ?? note.from) - note.from) * progress
                phase += 2 * .pi * freq / sampleRate
                let attack = min(1, t / 0.004)
                let decay = exp(-5 * progress) * (1 - progress)
                let wave = sin(phase) + 0.18 * sin(2 * phase)
                out[first + n] += Float(wave * attack * decay * note.volume)
            }
        }
        return buffer
    }
}
