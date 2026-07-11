import SwiftUI
import SummitCore
import Foundation

@Observable
final class MusicStore {
    var chordText: String = ""
    var chords: [ChordVoice] = []
    var tempo: Double = 92
    var strum: Bool = false
    var transpose: Int = 0
    var isPlaying: Bool = false
    var savedSongName: String = ""
    // Chords that have actually sounded this run, newest first, capped at 24. Feeds
    // the calc display's chord-memory wheel. ponytail: session-only, not persisted —
    // it's a "what did I just play" viewer, meaningless across launches.
    var playedChordNames: [String] = []
    var playOnKeys: Bool = false {
        didSet { persistKeyChords() }
    }
    var cycleOnTabSwitch: Bool = false {
        didSet { persistKeyChords() }
    }

    static let samples: [(String, String)] = [
        ("pop", "C G Am F"),
        ("campfire", "G D Em C"),
        ("blues", "A7 D7 A7 E7 D7 A7"),
        ("jazz", "Dm7 G7 Cmaj7")
    ]

    private let synth = MusicSynth()
    private var playTask: Task<Void, Never>?
    private var cycleIndex: Int = 0
    private static let cycleDuration: Double = 0.6
    private static let keyChordsFileName = "summit_keychords"

    private struct KeyChordsPersist: Codable {
        var on: Bool
        var text: String
        var cycle: Bool?
    }

    init() {
        guard let persisted = Self.loadPersistedKeyChords() else { return }
        if persisted.on, !persisted.text.isEmpty {
            chordText = persisted.text
            cycleOnTabSwitch = persisted.cycle ?? false
            loadChords()
            if !chords.isEmpty {
                playOnKeys = true
            }
        } else {
            cycleOnTabSwitch = persisted.cycle ?? false
        }
    }

    func loadChords() {
        chords = ChordParser.parseText(chordText)
        transpose = 0
        cycleIndex = 0
        persistKeyChords()
    }

    func playChord(_ voice: ChordVoice) {
        recordPlayed(voice)
        let notes = voice.midiNotes.map { $0 + transpose }
        let duration = 60.0 / tempo * 2.2
        synth.playChord(midiNotes: notes, strum: strum, duration: duration)
    }

    private func recordPlayed(_ voice: ChordVoice) {
        playedChordNames.insert(voice.symbol, at: 0)
        if playedChordNames.count > 24 { playedChordNames.removeLast() }
    }

    func playDigitChord(_ digit: Int) {
        guard !chords.isEmpty else { return }
        let count = chords.count
        let index = ((digit % count) + count) % count
        let voice = chords[index]
        recordPlayed(voice)
        let notes = voice.midiNotes.map { $0 + transpose }
        let duration = 60.0 / tempo * 1.7
        synth.playChord(midiNotes: notes, strum: strum, duration: duration)
    }

    func playAll() {
        guard !chords.isEmpty else { return }
        stopAll()
        isPlaying = true
        let beat = 60.0 / tempo * 2.0
        let sequence = chords
        playTask = Task { @MainActor in
            for chord in sequence {
                guard !Task.isCancelled else { break }
                playChord(chord)
                try? await Task.sleep(nanoseconds: UInt64(beat * 1_000_000_000))
            }
            isPlaying = false
        }
    }

    func stopAll() {
        playTask?.cancel()
        playTask = nil
        isPlaying = false
        synth.stopAll()
    }

    func loadSample(_ key: String) {
        if let match = Self.samples.first(where: { $0.0 == key }) {
            chordText = match.1
            loadChords()
        }
    }

    func nextCycledChord() -> ChordVoice? {
        guard !chords.isEmpty else { return nil }
        let idx = cycleIndex % chords.count
        cycleIndex = idx + 1
        return chords[idx]
    }

    func soundCycledChord(_ voice: ChordVoice) {
        recordPlayed(voice)
        let notes = voice.midiNotes.map { $0 + transpose }
        synth.playChord(midiNotes: notes, strum: strum, duration: Self.cycleDuration)
    }

    func saveSong(history: HistoryStore) {
        guard !chords.isEmpty else { return }
        let name = savedSongName.isEmpty ? chordText : savedSongName
        history.add(type: "song", title: name, value: "\(chords.count) chords", extra: ["text": chordText])
    }

    private static func keyChordsFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Summit", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(keyChordsFileName).appendingPathExtension("json")
    }

    private static func loadPersistedKeyChords() -> KeyChordsPersist? {
        guard let data = try? Data(contentsOf: keyChordsFileURL()) else { return nil }
        return try? JSONDecoder().decode(KeyChordsPersist.self, from: data)
    }

    private func persistKeyChords() {
        let payload = KeyChordsPersist(on: playOnKeys, text: chordText, cycle: cycleOnTabSwitch)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: Self.keyChordsFileURL(), options: .atomic)
    }
}
