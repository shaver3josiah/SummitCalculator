# Bloom v1.0 Parity Matrix

This register tracks feature parity between the Bloom Calculator v1.0 iOS release and the HTML reference (all-in-one.html frozen 2026-07-03). Specification of record is Bloom Calculator all-in-one.html. Issues are classified as P0 (core user-facing features broken or absent), P1 (visible gap in normal use), or P2 (nicety or polish).

## Main Feature Parity

| ID | Title | HTML anchor | Swift state | Class | Owner | Acceptance |
| --- | --- | --- | --- | --- | --- | --- |
| P-001 | Audio tap sounds bundled | L2832-2853 | fixed in working tree by A01, ships as v0.1.9, never shipped before | P0 | A01 | CI build inspector verifies all 13 named tap event mp3s appear in the final .app and keys are audible on the physical SE after the v0.1.9 install. |
| P-002 | Brand fonts bundled | L2189-2195 | project.yml resources key inert; Fonts.swift exists but Quicksand, Playfair Display, Great Vibes not confirmed in build | P0 | A01 | Screenshot of live Calculator view shows Great Vibes header text and Playfair Display numerals rendering; font names verified in Xcode Assets. |
| P-003 | Calculation export | L3629-3650 | No code found; export only exists for budget in BudgetView | P0 | A10 | Calculation result exports as text via native iOS share sheet and includes memo if present. |
| P-004 | Projection export grow mode | L3651-3680 | No code found; projection views exist but no export handler | P0 | A10 | Projection growth chart exports as text summary including growth rate and terminal value via native share. |
| P-005 | Projection export match mode | L3681-3710 | ProjectionView.swift exists but no match mode export | P0 | A10 | Match scenario exports as text including breakeven and target dates via native share. |
| P-006 | Projection export retire mode | L3711-3740 | RetirePanel.swift exists but no retire mode export | P0 | A10 | Retire scenario exports as text including annual need and timeline via native share. |
| P-007 | Projection export real rate mode | L3741-3770 | RealRatePanel.swift exists but no real rate mode export | P0 | A10 | Real rate scenario exports as text including inflation-adjusted values via native share. |
| P-008 | Projection export rule72 mode | L3771-3800 | RuleOf72Panel.swift exists but no rule72 mode export | P0 | A10 | Rule of 72 calculation exports as text including doubling time via native share. |
| P-009 | Lists export | L3801-3830 | ListsView.swift exists but no export handler for lists; only budget export works | P1 | A10 | List exports as text with item names and quantities via native share, honoring current sort order. |
| P-010 | Kitchen convert export | L3851-3880 | ConvertPanel.swift exists but no export handler | P1 | A10 | Unit conversion result exports as text via native share, showing source and target with units. |
| P-011 | Recipe export | L3881-3910 | RecipePanel.swift exists but no export handler | P1 | A10 | Recipe exports as text with ingredient list and instructions via native share. |
| P-012 | Budget export | L3911-3940 | BudgetView.swift has export/import; export works, format is base64 JSON per HTML L3916 | P0 | A10 | Budget exports as base64 JSON string via native share and includes categories, amounts, and monthly totals. |
| P-013 | Chords export | L3941-3970 | MusicStore.swift exists but no chord sequence export | P1 | A10 | Chord sequence exports as text list via native share showing selected chords in order. |
| P-014 | Tools export | L3971-4000 | ToolsView.swift exists but no export handler | P1 | A10 | Tool results export as text via native share, showing calculation method and result. |
| P-015 | History export | L4001-4030 | HistoryOverlay.swift exists but no export handler | P1 | A10 | Calculation history exports as text list via native share showing date, operation, and result. |
| P-016 | Import dispatch budget first | L3887-3892 | BudgetStore.swift has import logic | P0 | A20 | Pasting a budget export string imports and displays the budget, replacing current state. |
| P-017 | Import dispatch projection | L3887-3892 | ProjectionStore.swift exists but no import handler | P1 | A10 | Pasting projection export string recognizes format and imports projection parameters. |
| P-018 | Import dispatch chords | L3887-3892 | MusicStore.swift exists but no import handler | P1 | A10 | Pasting chord sequence export recognizes format and loads as playable sequence. |
| P-019 | Import dispatch list | L3887-3892 | ListsStore.swift exists but no import handler | P1 | A10 | Pasting list export recognizes format and imports list with all items and quantities. |
| P-020 | Import dispatch recipe | L3887-3892 | KitchenStore.swift exists but no import handler | P1 | A10 | Pasting recipe export recognizes format and loads ingredient list. |
| P-021 | Auto-copy on open | L3910-3920 | No code found | P1 | A20 | When entering a share sheet, calculation or list result is automatically copied to clipboard with confirmation toast. |
| P-022 | Native share gate | L3925-3935 | No code found | P1 | A20 | Share buttons and exports only show native iOS share sheet when supported on the device; web-share fallback removed. |
| P-023 | Music play toggle | L2975-2978 | SoundStore.swift exists; toggle renders system green instead of primaryStrong token | P1 | A11 | Music Play toggle renders with correct primaryStrong color (dark pink) and is visually distinct from disabled state. |
| P-024 | Keychords toggle | L2975-2978 | No code found for play-chords-on-calculator-keys setting | P1 | A11 | Toggle for calculator key chord playback exists in Music settings and responds to user interaction. |
| P-025 | Projection history reopen | L2189-2195 | ProjectionStore.swift exists but history rows cannot be reopened to edit | P1 | A12 | Tapping a projection history row reopens that scenario for editing with all prior values loaded. |
| P-026 | Projection fund defaults | L2197-2216 | Defaults hard-coded as Swift literal in ProjectionStore.swift | P1 | A12 | Projection screen shows default fund allocations matching HTML source (L2197-2216) and allows editing. |
| P-027 | Projection mode chips scroll | L2189-2195 | ProjectionView.swift segmented row clips "Compare" label on SE with no scroll cue | P1 | A12 | Segmented row for projection modes (Grow, Match, Retire, Real Rate, Rule72) wraps or scrolls horizontally with visible peek or fade indicator on SE. |
| P-028 | Projection fund chips scroll | L2189-2195 | ProjectionView.swift fund filter chips clip "Aggressive" on SE with no scroll cue | P1 | A12 | Fund allocation chips scroll horizontally with visible scroll cue or fade on SE; all options reachable. |
| P-029 | History day grouping | L2521-2584 | HistoryOverlay.swift exists but grouping by Today/Yesterday/Day of week not implemented | P1 | A13 | History rows group by day (Today, Yesterday, Mon/Tue/etc) with pinned group (Today) first and 200-item cap honoring favorites exemption. |
| P-030 | History pinned group | L2521-2584 | HistoryStore.swift has no pinned group logic | P1 | A13 | Favorited history items appear in a pinned section at top of history overlay. |
| P-031 | History card display | L2525-2530 | HistoryOverlay.swift renders rows but pretty card format not implemented | P1 | A13 | History items display on a pretty card with emoji, date, time, operation, and result; card design matches HTML. |
| P-032 | History print mode | L2525-2530 | No code found | P1 | A13 | History supports print mode for displaying history as a formatted page via native print sheet. |
| P-033 | Radius scale tokens | L14-26 | ThemeStore.swift collapses all radii to single value; spec requires 22, 24, 16, 12, pill | P1 | A14 | All rounded corners use correct radius scale: pill for buttons and chips, 24 for cards, 16 for input fields, 12 for secondary, 22 for hero elements. |
| P-034 | Shadow layers sh1 | L27-35 | ThemeStore.swift does not define layered shadow system; spec requires sh1 sh2 sh3 | P1 | A14 | Small elevation shadow (sh1) renders on cards and low-elevation elements with correct blur and offset per design tokens. |
| P-035 | Shadow layers sh2 | L27-35 | ThemeStore.swift missing sh2 shadow definition | P1 | A14 | Medium elevation shadow (sh2) renders on modals and mid-elevation elements with correct blur and offset per design tokens. |
| P-036 | Shadow layers sh3 | L27-35 | ThemeStore.swift missing sh3 shadow definition | P1 | A14 | High elevation shadow (sh3) renders on overlays and high-elevation elements with correct blur and offset per design tokens. |
| P-037 | Ring token styling | L36-42 | ThemeStore.swift does not define ring token for focus states | P1 | A14 | Focus ring appears on keyboard-accessible elements using ring token with correct stroke and offset. |
| P-038 | viewIn animation | L84-90 | No animation code found matching 0.35-0.45s cubic-bezier spec | P1 | A15 | View entrance animates with cubic-bezier(0.22,1,0.36,1) over 0.35-0.45s; timing verifiable in device recording. |
| P-039 | histIn stagger animation | L91-100 | HistoryOverlay.swift renders but no stagger animation | P1 | A15 | History rows stagger into view at 0.04s per item offset using histIn timing curve. |
| P-040 | Keypad ripple animation | L101-110 | KeypadButton.swift exists but ripple animation not implemented | P1 | A15 | Keypad buttons animate ripple effect on tap lasting 0.6s with color expanding from tap point. |
| P-041 | Sheet rise animation | L111-120 | Modals and overlay sheets exist but rise animation not implemented | P1 | A15 | Modal sheets animate upward with sheetUp timing (0.4s) from bottom edge. |
| P-042 | Toast flower spin | L121-130 | ToastHost.swift exists but flower icon does not spin; spec requires 6s full rotation | P1 | A15 | Toast notification flower icon rotates continuously at 6s per full rotation when visible. |
| P-043 | Fade animation | L131-140 | Component fade-ins/fade-outs not systematically implemented | P1 | A15 | Elements fade in and out over appropriate durations per screen context and HTML spec. |
| P-044 | Poem reveal animation | L1874-1885 | PoemOverlay.swift exists but entrance animation not matching 0.85s poemIn spec | P1 | A15 | Poem overlay reveals with poemIn animation (0.85s base) plus line stagger (0.7s per line) forming entrance cascade. |
| P-045 | Poem line stagger | L1874-1885 | PoemOverlay.swift renders poem but no per-line stagger animation | P1 | A15 | Individual poem lines appear with 0.35s base timing plus 0.7s per-line stagger offset, creating waterfall effect. |
| P-046 | RevealPulse animation | L141-150 | SplashOverlay.swift or equivalent exists but revealPulse (2.8s) not implemented | P1 | A15 | Reveal effect pulses outward at 2.8s total duration on designated splash screens. |
| P-047 | MoreIn animation | L151-160 | No code found for moreIn entrance (0.8s) | P1 | A15 | More hub and expanded menu items animate entrance with moreIn timing (0.8s). |
| P-048 | BloomIn splash animation | L161-170 | SplashOverlay.swift exists but bloomIn splash (1.1s flower entrance) not implemented | P1 | A15 | Splash screen flower animates bloomIn (1.1s) with petal unfold effect on app launch. |
| P-049 | RollNumber count-up animation | L171-180 | RollingNumberText.swift exists but count-up animation timing (750ms) unverified | P1 | A15 | Numeric displays animate count-up from prior value to new value over 750ms with easing. |
| P-050 | Projection chart draw-in | L2240-2261 | GrowPanel.swift renders chart but dashoffset draw-in animation not implemented | P1 | A15 | Projection curve chart animates line draw using dashoffset from empty to full coverage. |
| P-051 | Projection compare bars | L2709-2721 | ComparePanel.swift renders bars but grow animation not implemented using requestAnimationFrame equivalent | P1 | A15 | Comparison bar chart animates bars growing from zero to final height using SwiftUI animation. |
| P-052 | Toast burst animation | L2105-2118 | ToastHost.swift exists but 14-petal burst pattern not implemented | P1 | A15 | Toast notifications display animated 14-petal burst pattern expanding outward on completion. |
| P-053 | Flower scale animation | L2272-2273 | FlowerLogo.swift exists but flower does not scale in response to growth ratio | P1 | A15 | Flower logo in projection grows visually in response to growth ratio percentage with smooth animation. |
| P-054 | Lists save moment animation | L2297-2328 | ListsView.swift exists but save moment lacks rollNumber and petal burst animation | P1 | A16 | When saving a list, rollNumber animates total and petal burst fires, with audio confirmation. |
| P-055 | Lists name truncation | L2297-2328 | shipped, device-verify only | CLOSED-v0.1.8 | A16 | List names display fully without truncation, wrapping to second line if needed; seed data cleaned. |
| P-056 | Lists shape contract | L2297-2328 | ListsView.swift may use bloomShopLists vs bloom_lists shape per contract D9 | P1 | A16 | List shape contracts to D9 migration; bloomShopLists renames to bloom_lists consistently. |
| P-057 | Kitchen theme isolation | L871-903 | KitchenView.swift or kitchen subcomponents use separate bloomKitchenTheme copy rather than shared ThemeStore | P1 | A17 | Kitchen panels (Convert, Recipe, Visualize) use single shared ThemeStore instead of local theme copy; design tokens stay synchronized. |
| P-058 | Kitchen facts modal | L1472 | KitchenView.swift exists but facts modal not found | P1 | A17 | Kitchen displays facts/tips modal accessible from recipe or visualize panel explaining ingredient matches or conversions. |
| P-059 | Kitchen add-to-list flow | L3081 | KitchenStore.swift exists but add-to-list dispatch from recipe or convert not implemented | P1 | A17 | User can add recipe ingredients or converted amount to an existing list with confirmation toast. |
| P-060 | Tab consolidation to five | L2189-2195 | BloomTabBar.swift and BloomTab.swift render seven tabs (Calc, Projection, Lists, Kitchen, Tools, Budget, Music) | P1 | A20 | App displays five tabs (Calculator, Projection, Budget, Kitchen, More) per HIG; Lists, Tools, Music move into More hub. |
| P-061 | Global header share button | L3925 | RootView.swift header does not include global share button | P1 | A20 | Header displays share button launching global export menu for current view's content. |
| P-062 | History overlay layer | L2521-2584 | HistoryOverlay.swift renders as overlay; spec intended as persistent tab or sidebar | P1 | A20 | History remains accessible as overlay rather than tab per native iOS patterns and accepted divergence. |
| P-063 | Placeholder text color | L2189-2195 | shipped, device-verify only | CLOSED-v0.1.8 | A21 | Placeholder text in all input fields renders at muted token color (4.77:1 ratio) matching HTML source and passing WCAG AA for readability. |
| P-064 | Calculator display legibility | L2189-2195 | CalcView.swift renders result but no explicit legibility guardrails | P1 | A21 | Calculator display is readable at all font sizes and does not clip or overflow on any target device (SE, 16, 17). |
| P-065 | Memory bar contrast | L59-67 | Memory keys render at 2.55:1 (fails AA) per critique due to pink on light pink; should use strong token | P1 | A21 | Memory key indicators (MC, MR, M+, M-) render with strong pink text (3.97:1 pass) or use non-color visual cue. |
| P-066 | Equals button fill | L27-35 | open, keypad styling untouched by Phase 0 | P1 | A21 | Equals key carries the strong fill as the keypad's single accent and its label passes the large-text 3:1 floor. |
| P-067 | Keypad ripple prominence | L101-110 | KeypadButton.swift may lack visible ripple feedback on tap | P1 | A21 | Keypad buttons display animated ripple on tap with high contrast against background. |
| P-068 | Budget row overflow | L10 | BudgetView.swift budget row has chevron clipped behind toggle, labels truncate at 375pt | P1 | A23 | Budget category rows display full label text with line wrapping; chevron fully visible; toggle positioned to avoid overlap. |
| P-069 | Budget trailing toggles | L10 | BudgetView.swift toggles positioned in trailing edge; layout cramps on SE | P1 | A23 | Budget category row toggles reflow to maintain minimum 44pt hit area without overlapping disclosure controls. |
| P-070 | Budget name wrapping | L10 | BudgetView.swift category names truncate at "Renters or home insu..." | P1 | A23 | Budget category names wrap to multiple lines on SE without truncation; wrapping visible in live app. |
| P-071 | Budget goals chart today marker | L3310-3357 | GoalsCard.swift renders chart but today marker not placed per HTML spec | P1 | A23 | Goals chart displays vertical marker for current date/time position and updates daily. |
| P-072 | Budget goals chart legend | L3310-3357 | GoalsCard.swift chart lacks legend explaining goal line and actual line | P1 | A23 | Goals chart displays legend identifying goal (target) line and actual (current) progress line with color swatches. |
| P-073 | Budget year view month outline | L3358-3405 | YearView.swift renders year view but current month outline not implemented | P1 | A23 | Year view calendar displays outline or highlight on current month distinct from other months. |
| P-074 | Convert cup illustration | L2352-2376 | ConvertPanel.swift renders cup measure but fill animation and scale needle not implemented | P1 | A24 | Unit convert displays cup/measure illustration with animated fill level and scale needle responding to value changes. |
| P-075 | Poem sparkle effects | L1874-1885 | PoemOverlay.swift renders poem but sparkle particle effects not implemented | P1 | A26 | Poem text displays animated sparkles around verses or key words as per HTML spec. |
| P-076 | Poem auto-hide timer | L1874-1885 | PoemOverlay.swift does not implement 22s auto-hide per HTML spec | P1 | A26 | Poem overlay auto-hides after 22 seconds of display unless user interaction occurs. |
| P-077 | Poem structured blocks | L1874-1885 | PoemOverlay.swift renders poem but structured more blocks (note, head, verse, ask) not differentiated | P1 | A26 | Poem overlay renders different block types (note, head, verse, ask) with distinct formatting and spacing per design. |
| P-078 | Poem content Romans 8 | L1874-1885 | PoemOverlay.swift has poem content but Romans 8 payload completeness not verified | P1 | A26 | Poem overlay displays full Romans 8 passage text without truncation or clipping; all verses render. |
| P-079 | Toast egg 42 | L1874-1885 | ToastHost.swift renders toast but easter egg 42 not placed or documented | P1 | A26 | Toast reaches egg easter egg trigger at 42 notifications or appropriate condition; behavior documented. |
| P-080 | Toast egg 144 | L1874-1885 | ToastHost.swift renders toast but easter egg 144 not placed or documented | P1 | A26 | Toast reaches egg easter egg trigger at 144 notifications or appropriate condition; behavior documented. |
| P-081 | Toast egg near-miss silence | L1874-1885 | EasterEggs.swift may trigger near-miss eggs inappropriately | P1 | A26 | Near-miss egg conditions (values close to easter egg thresholds) remain silent and do not trigger effects. |
| P-082 | Splash egg 3/16/26 | contracts v3.1 | Not built; SplashOverlay exists dormant | P0 | A26 | Typing any 3/16/26 operator sequence (glyph or ascii) shows the Hannah / My Forever Love splash with petal shower; 3/16/25 still shows the original poems. |
| P-083 | Engagement toast eggs 7/25/26 | contracts v3.1 | Not built | P0 | A26 | Each of the four 7/25/26 operator sequences shows its short engagement toast with approved copy. |
| P-084 | Wedding sequences untouched | contracts v3.1 | Four frozen 12/5/26 poems already ship | P0 | A26 | Typing 12/5/26 sequences still shows the original frozen poems; no new entry collides with them. |
| P-085 | Celebration copy lock | contracts v3.1 | Proposed copy sits in contracts pending approval | P0 | A26 | Splash and toast copy carries Josiah's written approval before merge; approval noted in the diff. |
| P-086 | Celebration egg immunity | contracts v3.1 | New entries are additive to eggs.json | P0 | A30 | The ten existing eggs stay byte-identical, their 24 vectors pass unchanged, and every new sequence gains match and near-miss vectors. |
| P-087 | Visualization ingredient matching | L2521-2584 | shipped, device-verify only | CLOSED-v0.1.8 | A27 | Recipe visualizer matches ingredients including descriptors (large, unsalted, shredded, etc); specific food art renders for everyday recipes. |
| P-088 | Sound studio row count | L2881-2888 | SoundStudioView.swift must display 19 base rows plus 6 section rows totaling 25 option rows | P1 | A27 | Sound studio displays all option rows with no truncation or hidden scrolling on any target device. |
| P-089 | Sound studio option count | L2881-2888 | SoundStudioView.swift must show 15 selectable options across all categories | P1 | A27 | Sound studio lists all 15 audio options accessible without scroll; category grouping visible. |
| P-090 | Sound studio OFL credits | L2881-2888 | CreditsView.swift exists but OFL license attribution not verified | P1 | A27 | Sound studio displays credits section with OFL license attribution for all third-party audio assets. |
| P-091 | Hypothetical projections disclaimer | L2881-2888 | ProjectionView.swift or related disclaimer not found; locked warning required | P1 | A27 | Projection screens display locked disclaimer stating projections are hypothetical and require professional financial advice. |
| P-092 | Tools percentage label swap 1 | L2666-2667 | ToolsView.swift percentage tool must support label swapping for different modes | P1 | A28 | Percentage tool displays mode-specific labels that update when user switches between calculation modes. |
| P-093 | Tools percentage label swap 2 | L2666-2667 | ToolsView.swift percentage tool modes are not differentiated with distinct labels | P1 | A28 | Percentage tool shows four modes with distinct labels (e.g., Find Percent, Find Base, Find Amount, Find Increase). |
| P-094 | Safe area header iPhone 16 | L8 | RootView.swift header may use fixed offset rather than safe-area inset; risk on 59pt island | P1 | A24 | Header title and buttons respect 59pt Dynamic Island safe-area inset on iPhone 16; no overlap or odd gaps. |
| P-095 | Safe area tab bar iPhone 16 | L8 | BloomTabBar.swift tab bar may use fixed bottom offset rather than safe-area inset | P1 | A24 | Tab bar respects 34pt home indicator safe-area inset on iPhone 16; no overlap with controls. |
| P-096 | Safe area header iPhone 17 | L8 | RootView.swift header safe-area compliance for 17 unknown | P1 | A24 | Header title and buttons respect safe-area inset on iPhone 17 matching iPhone 16 handling. |
| P-097 | Safe area tab bar iPhone 17 | L8 | BloomTabBar.swift tab bar safe-area compliance for 17 unknown | P1 | A24 | Tab bar respects safe-area inset on iPhone 17 matching iPhone 16 handling. |
| P-098 | History black background | L2-37 | shipped, device-verify only | CLOSED-v0.1.8 | A24 | History overlay background matches theme (light pink) not pure black; no default system color renders. |
| P-099 | Recipe toggle contrast | L3-25 | shipped, device-verify only | CLOSED-v0.1.8 | A24 | Recipe toggle active segment uses strong pink fill with dark text passing 3.97:1 contrast ratio. |
| P-100 | Icon hit areas | L13 | mostly shipped in v0.1.8 (standalone buttons and 44pt-tall dense rows); listPicker and addRow plus icons still ~22-28pt | P2 | A33 | Every icon-only control reaches a 44pt hit area or carries a documented width compromise. |

## Intentional Divergences

| ID | Divergence | Reason |
| --- | --- | --- |
| DIV-001 | Native segmented controls instead of custom HTML modals | iOS HIG uses native UISegmentedControl style components; HTML used custom divs for compatibility |
| DIV-002 | Native sheets instead of custom HTML modals | iOS HIG prefers native bottom sheets and modal presentations over HTML overlays |
| DIV-003 | Visualize uses native rendering instead of iframe | iOS does not support iframe; native SwiftUI components render food visualization directly |
| DIV-004 | Music audio independent of master sound toggle | HTML behavior matches; iOS audio session respects Ring/Silent switch unless overridden via audio category |
| DIV-005 | Five tabs instead of seven per HIG | Apple HIG ceiling is five tabs on iPhone to ensure usability; consolidation improves label readability and touch targets |
| DIV-006 | Escape-key behaviors via native gestures | iOS has no Escape key; back swipe, dismiss gestures, and standard navigation replace keyboard shortcuts |
| DIV-007 | Keyboard navigation via system accessibility | iOS system keyboard navigation used instead of HTML key bindings; respects accessibility settings |
| DIV-008 | History as overlay not persistent tab | Native iOS patterns prefer overlay dialogs for supplementary information over adding tab bar items |
| DIV-009 | Native print controller instead of HTML print route | iOS print sheet invokes system print controller rather than HTML print media queries |

## Parking Lot (Post-1.0)

- Liquid Glass mode (v1.1, D10 decision)
- Universal share via iOS share extension forwarding to other apps
- iPad landscape and split-view layouts
- Localization and internationalization support
- App Store listing, marketing page, and TestFlight distribution (D11, restricted to TestFlight for v1.0)
- Android port or web wrapper
- Apple Watch companion app
- Siri Shortcut integration for calculations
- iCloud sync for lists, budget, and history
- Accessibility enhancements beyond WCAG AA (high contrast mode, system font scaling)
- Dark mode support beyond cherry theme (implemented as theme variants)
- Haptic feedback on key press and list save
- Homescreen widget for quick calculations
- Notification center widget
