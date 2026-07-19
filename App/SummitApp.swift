import SwiftUI
import SummitCore

@main
struct SummitApp: App {
    @State private var themeStore = ThemeStore()
    @State private var historyStore: HistoryStore
    @State private var soundStore: SoundStore
    @State private var listsStore = ListsStore()
    @State private var kitchenStore = KitchenStore()
    @State private var musicStore: MusicStore
    @State private var calcStore: CalcStore
    @State private var projectionStore = ProjectionStore()
    @State private var budgetStore = BudgetStore()
    @State private var notesArchive = NotesArchiveStore()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let history = HistoryStore()
        let sounds = SoundStore()
        let music = MusicStore()
        sounds.digitChordHook = { [weak music] digit in
            guard let music, music.playOnKeys, !music.chords.isEmpty else { return false }
            music.playDigitChord(digit)
            return true
        }
        _historyStore = State(initialValue: history)
        _soundStore = State(initialValue: sounds)
        _musicStore = State(initialValue: music)
        _calcStore = State(initialValue: CalcStore(history: history, sounds: sounds))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .environment(themeStore)
                .environment(historyStore)
                .environment(soundStore)
                .environment(listsStore)
                .environment(kitchenStore)
                .environment(musicStore)
                .environment(calcStore)
                .environment(projectionStore)
                .environment(budgetStore)
                .environment(notesArchive)
                // Leaving the app is the last guaranteed moment to write the
                // in-progress note down; the debounce may still be pending.
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { notesArchive.flushDraft() }
                }
        }
    }
}
