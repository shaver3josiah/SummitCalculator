import AVFoundation

struct ChordVoice {
    var midiNotes: [Int]
    var symbol: String
}

final class MusicSynth: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private let reverb = AVAudioUnitReverb()
    private var sourceNode: AVAudioSourceNode?
    private var configured = false

    private struct Voice {
        var frequency: Double
        var startSample: Double
        var releaseSample: Double?
        var velocity: Double
        var active: Bool
    }

    private let lock = NSLock()
    private var voices: [Voice] = []
    private var sampleClock: Double = 0
    private let sampleRate: Double = 44100

    private static let harmonicCount = 16
    private static let harmonicAmplitudes: [Double] = {
        var amps: [Double] = []
        amps.reserveCapacity(harmonicCount)
        for n in 0..<harmonicCount {
            if n == 0 {
                amps.append(0.0)
                continue
            }
            let rolloff: Double = n <= 6 ? 1.0 : 0.6
            amps.append(1.0 / Double(n) * rolloff)
        }
        return amps
    }()

    func start() {
        if !configured {
            guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
            let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
                self?.render(frameCount: frameCount, audioBufferList: audioBufferList) ?? noErr
            }
            sourceNode = node
            engine.attach(node)
            engine.attach(mixer)
            engine.attach(reverb)
            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = 25
            engine.connect(node, to: mixer, format: format)
            engine.connect(mixer, to: reverb, format: format)
            engine.connect(reverb, to: engine.mainMixerNode, format: format)
            mixer.outputVolume = 0.6
            configured = true
        }
        guard !engine.isRunning else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            engine.prepare()
            try engine.start()
        } catch {
            engine.stop()
        }
    }

    func playChord(midiNotes: [Int], strum: Bool, duration: Double) {
        start()
        lock.lock()
        let baseSample = sampleClock
        for (i, midi) in midiNotes.enumerated() {
            let freq = 440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)
            let delay = strum ? Double(i) * 0.02 * sampleRate : 0
            let voice = Voice(
                frequency: freq,
                startSample: baseSample + delay,
                releaseSample: baseSample + delay + duration * sampleRate,
                velocity: i == 0 ? 0.95 : 0.75,
                active: true
            )
            voices.append(voice)
        }
        if voices.count > 96 {
            voices.removeFirst(voices.count - 96)
        }
        lock.unlock()
    }

    func stopAll() {
        lock.lock()
        voices.removeAll()
        lock.unlock()
    }

    private func render(frameCount: AVAudioFrameCount, audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        guard let buffer = ablPointer.first, let rawData = buffer.mData else { return noErr }
        let samples = rawData.assumingMemoryBound(to: Float.self)

        lock.lock()
        defer { lock.unlock() }

        for frame in 0..<Int(frameCount) {
            let now = sampleClock + Double(frame)
            var mixSample = 0.0

            for idx in voices.indices {
                guard voices[idx].active else { continue }
                let voice = voices[idx]
                guard now >= voice.startSample else { continue }
                let age = (now - voice.startSample) / sampleRate
                guard age >= 0 else { continue }

                let releaseAge: Double
                if let release = voice.releaseSample {
                    releaseAge = (now - release) / sampleRate
                } else {
                    releaseAge = -1
                }

                let envelope = envelopeValue(age: age, releaseAge: releaseAge)
                if envelope <= 0.0001 && releaseAge > 0.1 {
                    voices[idx].active = false
                    continue
                }

                let damping = min(1.0, age * 1.4)
                var harmonicSum = 0.0
                for n in 1..<Self.harmonicCount {
                    let amp = Self.harmonicAmplitudes[n] * (1.0 - damping * Double(n) / Double(Self.harmonicCount))
                    guard amp > 0 else { continue }
                    let phase = 2.0 * Double.pi * voice.frequency * Double(n) * (age)
                    harmonicSum += sin(phase) * amp
                }
                mixSample += harmonicSum * envelope * voice.velocity * 0.12
            }

            let clamped = max(-1.0, min(1.0, mixSample))
            samples[frame] = Float(clamped)
        }

        sampleClock += Double(frameCount)
        voices.removeAll { !$0.active && ($0.releaseSample.map { sampleClock - $0 > sampleRate * 2 } ?? false) }
        return noErr
    }

    private func envelopeValue(age: Double, releaseAge: Double) -> Double {
        let attack = 0.008
        let decayTo = 0.35

        var value: Double
        if age < attack {
            value = age / attack
        } else {
            let decayTime = min(age - attack, 1.2)
            value = 1.0 - (1.0 - decayTo) * min(1.0, decayTime / 1.2)
        }

        if releaseAge > 0 {
            let releaseDuration = 0.3
            let releaseFactor = max(0, 1.0 - releaseAge / releaseDuration)
            value *= releaseFactor
        }

        return max(0, value)
    }
}
