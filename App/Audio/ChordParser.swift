import Foundation

enum ChordParser {
    private static let pitchClasses: [String: Int] = [
        "C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11
    ]

    private static let qualities: [String: [Int]] = [
        "": [0, 4, 7],
        "m": [0, 3, 7],
        "min": [0, 3, 7],
        "maj": [0, 4, 7],
        "maj7": [0, 4, 7, 11],
        "m7": [0, 3, 7, 10],
        "min7": [0, 3, 7, 10],
        "7": [0, 4, 7, 10],
        "dim": [0, 3, 6],
        "dim7": [0, 3, 6, 9],
        "aug": [0, 4, 8],
        "sus2": [0, 2, 7],
        "sus4": [0, 5, 7],
        "6": [0, 4, 7, 9],
        "m6": [0, 3, 7, 9],
        "9": [0, 4, 7, 10, 14],
        "add9": [0, 4, 7, 14]
    ]

    static func parseToken(_ token: String) -> ChordVoice? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        var bassSymbol: String?
        var body = trimmed
        if let slashIdx = trimmed.firstIndex(of: "/") {
            body = String(trimmed[trimmed.startIndex..<slashIdx])
            bassSymbol = String(trimmed[trimmed.index(after: slashIdx)...])
        }

        guard let rootChar = body.first, let basePitch = pitchClasses[String(rootChar).uppercased()] else {
            return nil
        }

        var rest = String(body.dropFirst())
        var pitch = basePitch
        var accidental = ""
        if rest.first == "#" || rest.first == "\u{266F}" {
            pitch += 1
            accidental = "#"
            rest.removeFirst()
        } else if rest.first == "b" || rest.first == "\u{266D}" {
            pitch -= 1
            accidental = "b"
            rest.removeFirst()
        }

        // Single note: root + optional accidental + octave digit, e.g. E4, F#3, Bb5.
        // Octaves 6, 7 and 9 stay chords ("C6"/"G7"/"C9" are chord qualities above,
        // and dominant 7ths are everywhere) — the note piano only emits octaves
        // 2…5, so the collision never bites in-app.
        if rest.count == 1, let octave = rest.first?.wholeNumberValue,
           (0...8).contains(octave), octave != 6, octave != 7, octave != 9 {
            let midi = 12 * (octave + 1) + (((pitch % 12) + 12) % 12)
            guard (21...108).contains(midi) else { return nil }
            let noteDisplay = String(rootChar).uppercased() + accidental + rest
            return ChordVoice(midiNotes: [midi], symbol: noteDisplay)
        }

        let qualityKey = rest.isEmpty ? "" : rest
        guard let intervals = qualities[qualityKey] ?? qualities[qualityKey.lowercased()] else {
            return nil
        }

        let root = 48 + (((pitch % 12) + 12) % 12)
        var notes = intervals.map { root + $0 }

        if let bassSymbol, let bassChar = bassSymbol.first, let bassPitch = pitchClasses[String(bassChar).uppercased()] {
            let bassNote = 36 + (((bassPitch % 12) + 12) % 12)
            notes.insert(bassNote, at: 0)
        }

        let display = String(rootChar).uppercased() + rest + (bassSymbol.map { "/" + $0.uppercased() } ?? "")
        return ChordVoice(midiNotes: notes, symbol: display)
    }

    static func parseText(_ text: String) -> [ChordVoice] {
        let cleaned = text.replacingOccurrences(of: "|", with: " ")
        let tokens = cleaned.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "\n" })
        return tokens.compactMap { parseToken(String($0)) }
    }
}
