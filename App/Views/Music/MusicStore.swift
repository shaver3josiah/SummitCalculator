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
    // Title of the last-loaded library preset, shown above the pads. Cleared by
    // loadChords() so hand-edited text never wears a stale song name.
    var loadedSongTitle: String?
    // Chords that have actually sounded this run, newest first, capped at 24. Feeds
    // the calc display's chord-memory wheel. ponytail: session-only, not persisted —
    // it's a "what did I just play" viewer, meaningless across launches.
    var playedChordNames: [String] = []
    var playOnKeys: Bool = false {
        didSet {
            persistKeyChords()
            // Calculator keys can fire chords the moment this is on — boot the
            // engine now so the first key never pays the engine-start delay.
            if playOnKeys { warmUp() }
        }
    }
    var cycleOnTabSwitch: Bool = false {
        didSet { persistKeyChords() }
    }

    // Chord loudness multiplier (0.5…1.8, default 1.4 = +40%). Routed to the synth's
    // mixer: min(1.0, 0.6 × chordVolume). See MusicSynth.setVolume.
    var chordVolume: Double = 1.4 {
        didSet {
            synth.setVolume(Float(chordVolume))
            persistKeyChords()
        }
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
        var volume: Double?   // optional → old files without it decode to nil (default 1.4)
    }

    init() {
        if let persisted = Self.loadPersistedKeyChords() {
            chordVolume = persisted.volume ?? 1.4
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
        // didSet doesn't fire for in-init assignment, so push the (possibly default) volume once.
        synth.setVolume(Float(chordVolume))
        // Same in-init didSet gap for playOnKeys: warm the engine at launch when
        // key-chords are already on, so the very first calculator key is instant.
        if playOnKeys { warmUp() }
    }

    /// Boot the audio engine ahead of the first note. Idempotent and cheap once
    /// running — MusicView calls this on appear so pads/piano/play never wait
    /// for AVAudioEngine startup on the first tap.
    func warmUp() {
        synth.start()
    }

    func loadChords() {
        chords = ChordParser.parseText(chordText)
        transpose = 0
        cycleIndex = 0
        loadedSongTitle = nil
        persistKeyChords()
    }

    /// Load a library preset: chords in, pads ready, and the song's title kept
    /// for the "now loaded" line and the history save name.
    func loadSong(_ song: PresetSong) {
        chordText = song.chords
        loadChords()
        loadedSongTitle = song.title
        savedSongName = song.title
    }

    /// Sound one single note (from the note piano). Same synth voice as chords,
    /// so a lone note sounds with the same soft grand-piano tone.
    func playNote(midi: Int, symbol: String) {
        recordPlayed(ChordVoice(midiNotes: [midi], symbol: symbol))
        synth.playChord(midiNotes: [midi + transpose], strum: false, duration: 60.0 / tempo * 1.6)
    }

    /// Append one token (chord or note) to the song text with clean spacing.
    func appendToken(_ token: String) {
        if chordText.isEmpty || chordText.hasSuffix(" ") || chordText.hasSuffix("\n") {
            chordText += token
        } else {
            chordText += " " + token
        }
    }

    /// Remove the last token (and its trailing whitespace) from the song text.
    func removeLastToken() {
        while let last = chordText.last, last == " " || last == "\n" { chordText.removeLast() }
        while let last = chordText.last, last != " " && last != "\n" { chordText.removeLast() }
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
        playSequence(chords)
    }

    /// Play any chord line in order at the current tempo — the loaded pads use
    /// this via playAll, and the songwriter plays a section (or a whole song)
    /// through the same path, so everything sounds like one instrument.
    func playSequence(_ sequence: [ChordVoice]) {
        guard !sequence.isEmpty else { return }
        stopAll()
        isPlaying = true
        let beat = 60.0 / tempo * 2.0
        playTask = Task { @MainActor in
            for chord in sequence {
                // `return`, never `break`: a cancelled run must not fall through
                // to the isPlaying = false below, or it would clobber the state
                // of the run that just replaced it (tap two section-play buttons
                // in a row and Stop would vanish while audio kept going).
                guard !Task.isCancelled else { return }
                playChord(chord)
                try? await Task.sleep(nanoseconds: UInt64(beat * 1_000_000_000))
            }
            guard !Task.isCancelled else { return }
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
        let payload = KeyChordsPersist(on: playOnKeys, text: chordText, cycle: cycleOnTabSwitch, volume: chordVolume)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: Self.keyChordsFileURL(), options: .atomic)
    }
}
