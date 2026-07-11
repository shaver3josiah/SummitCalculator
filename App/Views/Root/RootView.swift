import SwiftUI
import SummitCore

struct RootView: View {
    @Environment(ThemeStore.self) private var themeStore
    @Environment(HistoryStore.self) private var historyStore
    @Environment(SoundStore.self) private var soundStore
    @Environment(MusicStore.self) private var musicStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedTab: SummitTab = .calc
    @State private var showThemeEditor = false
    @State private var slideForward = true
    @State private var verseMode = false

    var body: some View {
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
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
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
        // Leaf curtain only the first time she ever opens each tab.
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
