import SwiftUI
import SummitCore

struct RootView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(MusicStore.self) private var musicStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.verticalSizeClass) private var vSize
    @State private var selectedTab: SummitTab = .calc
    @State private var showThemeEditor = false
    @State private var slideForward = true
    @State private var verseMode = false

    // `landscape` is the DEBOUNCED effective orientation, not the raw size class:
    // a rotation only takes effect after a 300ms settle (see scheduleFlip), so
    // tilting the phone near the threshold doesn't thrash between layouts.
    // verticalSizeClass == .compact is iPhone landscape ONLY (iPad landscape stays
    // .regular → landscape never becomes true → iPad keeps portraitBody). portraitBody
    // is byte-for-byte the original body, so portrait can never regress.
    @State private var landscape = false
    @State private var didInitOrientation = false
    @State private var flipGeneration = 0

    var body: some View {
        Group {
            if landscape {
                landscapeBody
            } else {
                portraitBody
            }
        }
        .onAppear {
            // Seed the initial orientation with no delay (launching in landscape
            // shouldn't wait 300ms); subsequent changes go through the debounce.
            if !didInitOrientation {
                landscape = (vSize == .compact)
                didInitOrientation = true
            }
        }
        .onChange(of: vSize) { _, newValue in
            scheduleFlip(to: newValue == .compact)
        }
    }

    /// Debounced portrait⇄landscape switch: only the last change within a 300ms
    /// quiet window is applied, so rapid re-orientation can't flip the UI repeatedly.
    private func scheduleFlip(to want: Bool) {
        guard want != landscape else { return }
        flipGeneration &+= 1
        let generation = flipGeneration
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            guard generation == flipGeneration else { return }   // superseded by a newer change
            landscape = want
        }
    }

    // Landscape layout — the "bottom nodes on the right" look, for ALL tabs: content
    // fills the height on the left, the tab rail is a vertical strip on the right.
    // Calc shows the scientific keypad (it still clears ≥44pt keys after losing the
    // 68pt rail); every other tab shows its normal scroll view, now with the full
    // landscape height instead of losing it to a bottom bar.
    private var landscapeBody: some View {
        ZStack {
            themeStore.color("bg").ignoresSafeArea()
            HStack(spacing: 0) {
                landscapeContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                VerticalTabRail(selection: $selectedTab, onSelect: switchTab)
            }
            overlays
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
        .fullScreenCover(isPresented: historyPresentedBinding) {
            HistoryOverlay()
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView()
        }
        .sheet(isPresented: studioPresentedBinding) {
            SoundStudioView()
        }
    }

    @ViewBuilder
    private var landscapeContent: some View {
        switch selectedTab {
        case .calc:
            ScientificCalcView()
        case .proj:
            ProjectionView()
        case .lists:
            ListsView()
        case .kitchen:
            KitchenView()
        case .tools:
            ToolsView()
        case .budget:
            BudgetView()
        case .music:
            MusicView()
        }
    }

    private var portraitBody: some View {
        ZStack {
            themeStore.color("bg").ignoresSafeArea()
            // iPad readable-column cap: header + content + tab bar stay within 700pt,
            // centered. The bg fill and the overlays are siblings OUTSIDE this cap, so
            // they stay full-bleed edge-to-edge on wide screens. Tab bar is kept inside
            // the column so its buttons sit under the content, thumb-reachable.
            VStack(spacing: 0) {
                header
                content
                    .keyboardDoneBar()
                    .id(selectedTab)
                    .transition(contentTransition)
                SummitTabBar(selection: $selectedTab, onSelect: switchTab)
            }
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
            overlays
        }
        // Chrome integrity: the header band, verse ticker, display card, and tab bar
        // are fixed-height jewel layouts designed at standard type size. On a phone
        // with larger Dynamic Type the custom fonts scale up and burst those bands
        // (header text wrapping under the card, verse lines clipping — seen in the
        // field). Cap the app at the standard size so it renders as designed on every
        // device; sheets/covers inherit this through the presentation environment.
        .dynamicTypeSize(...DynamicTypeSize.large)
        .onAppear { _ = themeStore.firstVisit(selectedTab.rawValue) }   // launch tab: seen, no curtain
        .fullScreenCover(isPresented: historyPresentedBinding) {
            HistoryOverlay()
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView()
        }
        .sheet(isPresented: studioPresentedBinding) {
            SoundStudioView()
        }
    }

    private var header: some View {
        // The mark always stays. In verse mode the app name AND the buttons fade
        // out and the ticker owns the full width from the flower to the trailing
        // edge; the if/else swaps the whole subtree so no orphan HStack gap is left
        // behind the flower.
        HStack(spacing: 12) {
            TappableSummit(size: 38, onDoubleTap: toggleVerse)
            if verseMode {
                HeaderVerseTicker()
                    .frame(maxWidth: .infinity)
                    .transition(.opacity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Summit")
                        .font(summitScript(28))
                        .foregroundStyle(themeStore.color("deep"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Text("CALCULATOR & PROJECTIONS")
                        .font(summitBody(9, weight: .semibold))
                        .foregroundStyle(themeStore.color("muted"))
                        .tracking(1.2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)   // squeeze, never wrap under the card
                }
                .transition(.opacity)
                Spacer()
                headerButtons
                    .transition(.opacity)
            }
        }
        // Pin the header band to the ticker's height in BOTH modes so toggling verse
        // mode never jumps the header (the 66pt ticker is taller than the name/buttons).
        .frame(minHeight: HeaderVerseTicker.tickerHeight)
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private var headerButtons: some View {
        HStack(spacing: 10) {
            iconButton(system: "speaker.wave.2") {
                soundStore.isStudioPresented = true
            }
            iconButton(system: "clock") {
                historyStore.isPresented = true
            }
            iconButton(system: "pencil") {
                showThemeEditor = true
            }
        }
    }

    private func iconButton(system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(themeStore.color("primaryStrong"))
                .frame(width: 44, height: 44)
                .background(themeStore.color("surfaceSoft"))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var content: some View {
        switch selectedTab {
        case .calc:
            CalcView()
        case .proj:
            ProjectionView()
        case .lists:
            ListsView()
        case .kitchen:
            KitchenView()
        case .tools:
            ToolsView()
        case .budget:
            BudgetView()
        case .music:
            MusicView()
        }
    }

    private var overlays: some View {
        ZStack {
            if themeStore.leavesOn {
                LeafCurtainView(trigger: themeStore.curtainEpoch)
                    .allowsHitTesting(false)
            }
            ToastHost()
            PoemOverlay()
            SplashOverlay()
        }
    }

    private func toggleVerse() {
        withAnimation(SummitMotion.springSoft) {
            verseMode.toggle()
        }
        soundStore.play("modeswitch")
    }

    // Outgoing panel glides off, incoming glides in on the expo-out glide token.
    private var contentTransition: AnyTransition {
        guard !reduceMotion, themeStore.motionEnabled else { return .opacity }
        let inEdge: Edge = slideForward ? .trailing : .leading
        let outEdge: Edge = slideForward ? .leading : .trailing
        return .asymmetric(
            insertion: .move(edge: inEdge).combined(with: .opacity),
            removal: .move(edge: outEdge).combined(with: .opacity)
        )
    }

    private func switchTab(_ tab: SummitTab) {
        slideForward = tabOrder(tab) >= tabOrder(selectedTab)
        if reduceMotion || !themeStore.motionEnabled {
            selectedTab = tab
        } else {
            withAnimation(SummitMotion.glide) { selectedTab = tab }
        }
        // Leaf curtain only the first time you ever open each tab.
        if themeStore.firstVisit(tab.rawValue) {
            themeStore.triggerCurtain()
        }
        guard soundStore.enabled else { return }
        if musicStore.cycleOnTabSwitch, let chord = musicStore.nextCycledChord() {
            musicStore.soundCycledChord(chord)
        } else {
            soundStore.play("modeswitch")
        }
    }

    private func tabOrder(_ tab: SummitTab) -> Int {
        SummitTab.allCases.firstIndex(of: tab) ?? 0
    }

    private var historyPresentedBinding: Binding<Bool> {
        Binding(
            get: { historyStore.isPresented },
            set: { historyStore.isPresented = $0 }
        )
    }

    private var studioPresentedBinding: Binding<Bool> {
        Binding(
            get: { soundStore.isStudioPresented },
            set: { soundStore.isStudioPresented = $0 }
        )
    }
}
