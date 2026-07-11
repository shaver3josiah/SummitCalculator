# Bloom Contracts v1 (frozen)

> SUMMIT ADAPTATION NOTE, 2026-07-11: this repo is Summit Calculator, the masculine
> rustic sibling of Bloom. The contracts below are inherited verbatim from Bloom and
> remain the behavioral spec (all `Bloom*`/`bloom_*` identifiers now read
> `Summit*`/`summit_*` in code; share tags read `#summit-*`). Theme token VALUES are
> superseded by `contracts/theme-tokens.md` (Summit dark presets); easter-egg CONTENT
> is superseded by the mountain egg set in `Resources/eggs.json` (6 eggs). Everything
> else — engine APIs, formatters, persistence shapes, behavioral parity notes — still
> binds, and the cited HTML line anchors still refer to the Bloom source spec.

Every worker builds against this document. Deviations are bugs. Source spec: `../Bloom Calculator (all-in-one).html`.

> v2, 2026-07-03, approved deviation: the Lists/Kitchen/Pantry-era tab registry below is stale. The shipped app replaced the `pantry` tab with a `budget` tab (Monthly Budget engine) and the app display name is `Hannah's Calculator`, not `Bloom Calculator`. Both changes are called out inline below where they occur, and the frozen Budget API is appended as its own section at the end of this document.

> v3, 2026-07-08, approved additions and deviations: decisions D8 through D12, confirmed by Josiah. The seven-tab registry collapses to five (`calc, proj, budget, kitchen, more`); Lists, Music, Tools, Sound Studio, Theme editor, and Credits move under a new `more` hub. A `ShareCodec` API is frozen for cross-view share and import text. `ProjectionStore` gains history reopen. Fund defaults move into `BloomCore` as `FundDefaults`. `ListsStore` adopts the HTML's `bloom_lists` shape with a one-time migration from the legacy `bloomShopLists` shape. The theme token set gains 7 tokens (23 total) plus a full motion table. Calculator digit taps can route to keyboard chords. A date-celebration system is added. All changes are called out inline below where they occur, and the full v3 detail is appended as its own section at the end of this document.

## Global style rules

Swift 5.10+, iOS 17 minimum, zero third-party dependencies. No comments, no docstrings, no force unwraps outside tests, no em-dash characters anywhere. Files under 400 lines; split when larger. `BloomCore` imports Foundation only (must compile on Linux). UI code lives in `App/` and may import SwiftUI, AVFoundation, CoreImage, UIKit.

## File ownership registry

| Path | Owner |
|---|---|
| Packages/BloomCore/** | worker-core |
| App/BloomApp.swift, App/Theme/**, App/Components/**, App/Views/Root/**, App/Views/Calc/**, App/Views/Projection/**, App/Views/Tools/** | worker-finance-ui |
| App/Views/Lists/**, App/Views/Kitchen/**, App/Views/Pantry/**, App/Views/History/**, App/Views/Music/**, App/Views/Overlays/**, App/Effects/**, App/Audio/**, App/Views/Settings/** | worker-delight-ui |
| project.yml, .github/**, fastlane/**, scripts/**, App/Resources/** (non-Swift), App/Support/** | worker-scaffold |
| contracts/** | orchestrator only |

## BloomCore public API (signatures are frozen)

```swift
public enum CalcOp: String, Codable, Sendable { case add, subtract, multiply, divide }

public struct CalcResult: Equatable, Sendable {
    public let display: String
    public let expression: String
    public let sequence: String
}

public struct CalcEngine: Sendable {
    public private(set) var current: String
    public private(set) var overwrite: Bool
    public init()
    public mutating func digit(_ d: Character)
    public mutating func dot()
    public mutating func setOp(_ op: CalcOp)
    public mutating func equals() -> CalcResult?
    public mutating func clearAll()
    public mutating func toggleSign()
    public mutating func percent()
    public mutating func backspace()
    public var displayText: String { get }
    public var expressionText: String { get }
}

public enum FinanceMath {
    public static func futureValue(principal: Double, monthly: Double, annualRatePct: Double, years: Double) -> Double
    public static func contributions(principal: Double, monthly: Double, years: Double) -> Double
    public static func loanPayment(principal: Double, annualRatePct: Double, years: Double) -> Double
    public static func savingsGoalPayment(target: Double, principal: Double, annualRatePct: Double, years: Double) -> Double
    public static func realRate(nominalPct: Double, inflationPct: Double) -> Double
    public static func employerMatch(salary: Double, contribPct: Double, matchPct: Double, matchLimitPct: Double) -> Double
    public static func ruleOf72(ratePct: Double) -> Double
    public static func tip(bill: Double, tipPct: Double, people: Int) -> (tip: Double, total: Double, perPerson: Double)
    public static func percentOf(_ pct: Double, of value: Double) -> Double
    public static func percentChange(from a: Double, to b: Double) -> Double
}

public enum Formatters {
    public static func round8(_ n: Double) -> Double
    public static func fmt(_ n: Double) -> String
    public static func plain(_ n: Double) -> String
    public static func money(_ n: Double) -> String
    public static func usd(_ n: Double) -> String
}

public struct Egg: Codable, Equatable, Sendable {
    public let id: String
    public let kind: String
    public let title: String
    public let dateLabel: String
    public let lines: [String]
    public let more: [String]?
    public let triggers: [String]
}

public enum EasterEggs {
    public static func all() -> [Egg]
    public static func match(sequence: String) -> Egg?
}

public struct Fund: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var ratePct: Double
    public init(id: UUID, name: String, ratePct: Double)
}

public struct HistoryEntry: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var ts: Date
    public var type: String
    public var title: String
    public var value: String
    public var extra: [String: String]
    public init(id: String, ts: Date, type: String, title: String, value: String, extra: [String: String])
}

public struct ThemeSpec: Codable, Equatable, Sendable {
    public var name: String
    public var tokens: [String: String]
    public init(name: String, tokens: [String: String])
}

public struct Food: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var group: String
    public var measure: String
    public var glyph: String
    public var artKey: String?
}

public enum FoodLibrary {
    public static func load() -> [Food]
    public static func match(_ raw: String) -> Food?
    public static func groups() -> [String]
}

public struct ParsedIngredient: Codable, Equatable, Sendable {
    public var qty: Double?
    public var unit: String?
    public var name: String
    public var raw: String
}

public enum RecipeParse {
    public static func parseLine(_ line: String) -> ParsedIngredient?
    public static func scale(_ ing: ParsedIngredient, by factor: Double) -> ParsedIngredient
    public static func fmtQty(_ q: Double) -> String
    public static func cleanUrl(_ raw: String) -> String
    public static func jsonLDIngredients(html: String) -> [String]
}

public enum UnitConvert {
    public static let volumeUnits: [String]
    public static let weightUnits: [String]
    public static func convert(_ value: Double, from: String, to: String) -> Double?
}

public enum StoreKey: String, CaseIterable, Sendable {
    case history = "bloom_history"
    case favorites = "bloom_favorites"
    case funds = "bloom_funds"
    case theme = "bloom_theme"
    case custom = "bloom_custom"
    case soundmap = "bloom_soundmap"
    case recipes = "bloom_recipes"
    case shopLists = "bloomShopLists"
    case memory = "bloom_memory"
    case songs = "bloom_songs"
}

public final class JSONStore: @unchecked Sendable {
    public static let shared: JSONStore
    public func get<T: Decodable>(_ key: StoreKey, as type: T.Type) -> T?
    public func set<T: Encodable>(_ key: StoreKey, _ value: T)
    public func remove(_ key: StoreKey)
    public init(directory: URL)
}
```

## Behavioral parity notes (worker-core must read)

CalcEngine replicates HTML lines 1834-1911: left to right accumulator, chained ops compute immediately on second operator press, operator swap when pressed twice, divide by zero yields display "Error", equals returns nil when no pending op. `sequence` is the collapsed token string using glyphs ÷ × − + exactly as `checkEgg` receives it.

Formatters replicate lines 1809-1818 and 2049. round8 is `(n*1e8).rounded()/1e8`. fmt: if abs >= 1e15 or (abs < 1e-6 and n != 0) return exponential with 4 fraction digits in JS style `d.dddde+XX`; else group with en_US separators, max 8 fraction digits, no trailing zeros. plain: decimal string of round8 without grouping; values are multiples of 1e-8 so Swift shortest round trip printing matches JS; strip a trailing `.0`. money: `$` plus en_US grouping with exactly 2 fraction digits. usd: `$` plus whole dollar rounding with grouping.

FinanceMath.futureValue replicates lines 2037-2048: i = rate/100/12, n = years*12, if i == 0 then principal + monthly*n else principal*pow(1+i,n) + monthly*(pow(1+i,n)-1)/i.

EasterEggs.match: exact string match against each egg trigger list. Eggs load from bundled `eggs.json` (extracted verbatim from HTML lines 1694-1705, including `more` arrays). Near miss sequences must return nil.

Tests read `contracts/vectors.json` and assert string equality on every `expect` field, plus relative tolerance 1e-12 on every `raw` field.

## vectors.json schema (worker-extract produces, worker-core consumes)

```json
{
  "meta": {"generatedFrom": "Bloom Calculator (all-in-one).html", "date": "2026-07-02", "runtime": "node"},
  "formatters": [{"fn": "fmt|plain|money|usd", "arg": 1234.5678, "expect": "1,234.5678"}],
  "finance": [{"fn": "futureValue", "args": {"principal": 1000, "monthly": 100, "annualRatePct": 6, "years": 10}, "raw": 123.0, "expect": "$123"}],
  "calc": [{"keys": ["3","+","1","6","+","2","5","="], "display": "44", "sequence": "3+16+25"}],
  "eggs": [{"sequence": "4÷16÷25", "match": "egg-id-or-null"}],
  "recipe": [{"line": "1 ½ cups flour", "qty": 1.5, "unit": "cup", "name": "flour"}],
  "convert": [{"value": 2, "from": "cup", "to": "mL", "expect": 473.176}]
}
```

Minimum vector counts: formatters 40, finance 30 spanning all functions including zero rate and zero years edges, calc 25 including chained ops, operator swap, percent, sign toggle, divide by zero, eggs 24 covering all 10 eggs in both glyph and slash notation plus 4 near misses, recipe 20 including unicode fractions ½ ⅓ ¼ ¾ and word numbers, convert 12.

## UI registry (both UI workers)

App target name `Bloom`, entry `BloomApp` (owner: finance-ui). Root view `RootView` with custom bottom `BloomTabBar` over cases: calc, proj, ~~lists~~, kitchen, ~~tools~~, ~~pantry~~ budget, ~~music~~. **(v2, 2026-07-03, approved deviation: the `pantry` tab was replaced by `budget`, backed by `BudgetStore` and the `BloomCore` Budget API below; see the Budget section at the end of this document.)** **(v3, 2026-07-08, approved deviation: `lists`, `tools`, and `music` no longer have their own tab; `BloomTabBar` collapses to five cases in the order `calc, proj, budget, kitchen, more`, with `lists`, `music`, and `tools` reachable through the new `more` hub instead. See the Tab Registry v3 section at the end of this document.)** Stores are `@Observable` classes injected via `.environment(...)`: `CalcStore, ProjectionStore, HistoryStore, ListsStore, KitchenStore, ThemeStore, SoundStore, MusicStore, BudgetStore` (CalcStore, ProjectionStore, ThemeStore owned by finance-ui; BudgetStore owned by finance-ui per the v2 deviation; the rest by delight-ui; every store persists through `JSONStore.shared` with its StoreKey).

View names are frozen so RootView compiles: `CalcView, ProjectionView, ToolsView, BudgetView` (finance-ui, BudgetView added under the v2 deviation); `ListsView, KitchenView, MusicView, HistoryOverlay, PoemOverlay, ToastHost, SoundStudioView, RecycleSheet, SplashOverlay, CreditsView` (delight-ui; `PantryView` removed under the v2 deviation). Delight views must exist even if a sub-feature ships as a stub with a TODO screen; compile success on CI is the gate. **(v3, 2026-07-08, approved addition: `MoreView` and `ShareSheetView` join the finance-ui list as new frozen view names, `MoreView` a designed hub grid holding Lists, Music, Tools, Sound Studio, Theme editor, and Credits, `ShareSheetView` the global share and import sheet; `ThemeEditorView` (already implemented and wired into `RootView`'s pencil-icon sheet, but never formally frozen in v1 or v2) is retroactively added to the finance-ui list here too. `ListsView, MusicView, ToolsView, SoundStudioView, CreditsView` keep their existing names, file paths, and delight-ui ownership exactly as frozen above; only their navigation route changes, from a dedicated tab to a tile in the `more` hub. `HistoryOverlay` is unchanged, still an overlay reached from the header. See the Tab Registry v3 section at the end of this document.)**

Theme: `ThemeStore` exposes `spec: ThemeSpec` and `color(_ token: String) -> Color`. The ~~16~~ 23 tokens: bg, surface, surfaceSoft, surface2, primary, primaryStrong, deep, text, muted, line, flowerCenter, good, shadow, ripple, sh1, radius (radius is a CGFloat-encoded string), plus radiusLg, radiusMd, radiusSm, radiusPill, sh2, sh3, ring. **(v3, 2026-07-08, approved addition: 7 new tokens added to the frozen 16; see the Design Tokens v3 section at the end of this document for exact values and derivations. `contracts/theme-tokens.md` still documents only the original 16 and needs a companion update; that file is read-only reference for this agent and was not edited here.)** Presets cherry, rose, peony, soft come from `contracts/theme-tokens.md` hex values exactly. Custom theme edits any of the 12 editable tokens via ColorPicker and persists.

Sound event IDs (19, from HTML DEFAULT_MAP): tap digits rotate tap1 to tap5, plus operator, equals, clear, error, success, modeswitch, memory, easteregg, startup. `SoundStore.play(_ event: String)` resolves the user map, respects a master toggle, uses AVAudioSession category ambient. Haptics: light impact on keypad, success notification on egg, gated by a toggle in SoundStudioView.

Reduce motion: every particle system and long animation checks `@Environment(\.accessibilityReduceMotion)`.

## Scaffold registry (worker-scaffold)

Bundle id `com.shaver.bloomcalculator`, display name ~~`Bloom`~~ `Hannah's Calculator` **(v2, 2026-07-03, approved deviation)**, marketing version 1.0, build number from CI run number, deployment target 17.0, iPhone only, portrait plus portraitUpsideDown. Info.plist via project.yml: UIAppFonts (Quicksand, PlayfairDisplay, PlayfairDisplay-Italic, GreatVibes), ITSAppUsesNonExemptEncryption false. Secrets consumed in CI: APPLE_TEAM_ID, ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_P8. test.yml: swift:6.0 container on ubuntu-latest running `swift test` in Packages/BloomCore on every push. release.yml: macos-15, triggered by tags `v*`, steps: checkout, brew install xcodegen, scripts/fetch_fonts.sh, xcodegen, xcodebuild archive with cloud signing (`-allowProvisioningUpdates -authenticationKeyPath ... -authenticationKeyID ... -authenticationKeyIssuerID ...`), export ipa, `bundle exec fastlane pilot_upload`. Fonts fetched from pinned google/fonts GitHub raw URLs with sha256 checks, never committed.

## Budget (frozen, v2, 2026-07-03, approved addition)

Source spec: budget IIFE `Bloom Calculator (all-in-one).html:3113-3598`. Share text/tag: `exBudget` 3713-3735, `importBudget` 3832-3845, tag `#hannahs-budget-v1`. Owner: worker-core for `Packages/BloomCore/**`, worker-finance-ui for `App/Views/Budget/**`.

```swift
public struct BudgetRow: Codable, Equatable {
    public var n: String
    public var a: Double
    public var sel: Bool
    public init(n: String, a: Double, sel: Bool)
}

public struct BudgetIncome: Codable, Equatable {
    public var label: String
    public var gross: Double
    public var tax: Double
    public var ret: Double
    public var oth: Double
    public init(label: String, gross: Double, tax: Double, ret: Double, oth: Double)
}

public struct BudgetCategory: Codable, Equatable {
    public var n: String
    public var open: Bool
    public var goal: Double?
    public var items: [BudgetRow]
    public init(n: String, open: Bool, goal: Double?, items: [BudgetRow])
}

public struct BudgetMonth: Codable, Equatable {
    public var inc2On: Bool
    public var inc: [BudgetIncome]
    public var cats: [BudgetCategory]
    public init(inc2On: Bool, inc: [BudgetIncome], cats: [BudgetCategory])
}

public struct BudgetDB: Codable, Equatable {
    public var v: Int
    public var cur: String
    public var months: [String: BudgetMonth]
    public init(v: Int, cur: String, months: [String: BudgetMonth])
}

public struct BudgetPresetItem {
    public let name: String
    public let amount: Double
    public init(name: String, amount: Double)
}

public struct BudgetPreset {
    public let n: String
    public let items: [BudgetPresetItem]
    public init(n: String, items: [BudgetPresetItem])
}

public struct BudgetYearEntry: Equatable {
    public let key: String
    public let has: Bool
    public let planned: Double
    public let takeHome: Double
    public init(key: String, has: Bool, planned: Double, takeHome: Double)
}

public enum BudgetDefaults {
    public static func month() -> BudgetMonth
    public static let presets: [BudgetPreset]
    public static let colors: [String]
    public static let monthNames: [String]
}

public enum BudgetMath {
    public static func jsRound(_ x: Double) -> Double
    public static func netOf(_ i: BudgetIncome) -> Double
    public static func takeHome(of m: BudgetMonth) -> Double
    public static func catTotal(_ c: BudgetCategory) -> Double
    public static func catSel(_ c: BudgetCategory) -> Double
    public static func planned(of m: BudgetMonth) -> Double
    public static func importRow(name: String, qty: Double?, amount: Double) -> BudgetRow
    public static func ymKey(year: Int, month: Int) -> String
    public static func parseYM(_ key: String) -> (year: Int, month: Int)?
    public static func monthDays(_ ymKey: String) -> Int
    public static func monthLabel(_ ymKey: String) -> String
    public static func perDay(sel: Double, days: Int) -> Double
    public static func byToday(sel: Double, today: Int, days: Int) -> Double
    public static func chartYMax(sels: [Double], goals: [Double?]) -> Double
    public static func monthForSwitch(db: BudgetDB, to key: String) -> (month: BudgetMonth, copiedFrom: String?)
    public static func yearAggregate(db: BudgetDB, year: Int) -> [BudgetYearEntry]
}

public enum BudgetShare {
    public static func export(db: BudgetDB) -> String
    public static func parse(_ text: String) -> BudgetDB?
}
```

`StoreKey` gains `case budget2 = "bloom_budget2"` (raw value matches the JS `BKEY2` constant exactly; the case name is `budget2` to satisfy the `BudgetStore` UI call sites, not `budget`).

Behavioral parity notes: `jsRound` is `floor(x + 0.5)` including negatives (matches `Formatters.jsRound` already in the codebase). `netOf`: `gross * (1 - min(100, tax+ret+oth)/100)`, floored at 0. `takeHome`: `netOf(inc[0])` plus `netOf(inc[1])` only when `inc2On`. `catTotal`/`catSel` sum `item.a` over all items, or only `sel` items respectively. `planned` sums `catTotal` over all categories. `importRow`: `qty` nil (or the JS `''`/`null` equivalent) defaults to 1; `a = jsRound(qty*amount*100)/100`; `name` is trimmed then truncated to 60 characters; `sel` is always `false`. `monthDays` mirrors JS `new Date(y, m, 0).getDate()` (last day of month `m`, 1-indexed). `monthLabel` is `monthNames[month-1] + " " + year` (e.g. "July 2026"). `chartYMax`: base 1, then the max of every `sel` and `goal ?? 0` per series; if more than one series, also compare against the sum of all `sel` values; multiply the result by 1.08. `monthForSwitch`: if the target key exists, return it with `copiedFrom: nil`; otherwise search existing keys sorted ascending for the largest key strictly less than the target, falling back to the lexicographically-last existing key, falling back to `BudgetDefaults.month()` if no months exist at all; deep-copy the source, reset every item's `sel` to `false`, leave `goal` fields unchanged; `copiedFrom` is the source key used, or `nil` only when no months existed. `yearAggregate` walks months 1 through 12 of the given year and reports `has`/`planned`/`takeHome` (zeroed when absent).

Codable JSON keys are exact and match the JS payload shape: `BudgetRow` as `n, a, sel`; `BudgetIncome` as `label, gross, tax, ret, oth`; `BudgetCategory` as `n, open, goal, items`; `BudgetMonth` as `inc2On, inc, cats`; `BudgetDB` as `v, cur, months`. `BudgetCategory.goal` decodes from an explicit JSON `null` or an absent key identically (`decodeIfPresent`), and always encodes as an explicit `null` when `nil` (never an absent key), matching the JS `c.goal=c.goal` deep-copy-preserves-null-or-absent convention exactly.

`BudgetShare.export` replicates the JS `exBudget()` (lines 3713-3735) text template: `"Budget · " + label`, a summary line with take-home/planned/left via `money()`, an `INCOME` section, one line per category (`uppercased name — money(total)`, em dash), one line per non-empty item, an optional `(goal money(goal))` line when a goal is set, and a trailing `\n#hannahs-budget-v1 ` plus base64 of the UTF-8 JSON `{"k": cur, "m": month}` payload. `BudgetShare.parse` replicates `importBudget()` (lines 3832-3845): regex `#hannahs-budget-v1\s+([A-Za-z0-9+/=]+)`, base64-decode as UTF-8 JSON, guard on `payload.k` and non-empty `payload.m.cats`, and construct a fresh `BudgetDB(v: 2, cur: payload.k, months: [payload.k: payload.m])`. Byte-identical export text is not required; cross round-trip decodability is: a Swift-exported payload's base64 JSON must be parseable by the JS `importBudget` logic, and a JS-exported payload must be parseable by `BudgetShare.parse`. The JS `importBudget` additionally merges the imported month into whatever `BudgetDB` already exists in `localStorage` rather than replacing it outright; `BudgetShare.parse` returns a minimal single-month `BudgetDB` and leaves any merge-into-existing-store behavior to the caller.

Defaults are verbatim from the JS `defMonth()` (lines ~3134-3149): 11 categories (Housing through Everything Else), `Housing.open == true` and every other category closed, incomes `4200/18/5/2` and `3600/16/5/0`, `inc2On == true`. `PRESETS` (lines ~3120-3132): 12 presets including `Blank category` (which the UI relabels to "New category" on add). `COLORS` (line 3116) and `MONTHS` (line 3117) are transcribed verbatim as `BudgetDefaults.colors` (`[String]` hex values, Foundation-only per the BloomCore house rule; UI call sites convert via `Color(hex:)`) and `BudgetDefaults.monthNames`.

Vectors: `contracts/vectors.json` and `Packages/BloomCore/Tests/BloomCoreTests/Resources/vectors.json` carry 14 budget-prefixed keys (`budgetYmKey, budgetParseYM, budgetMonthLabel, budgetMonthDays, budgetChartYMax, budgetPerDay, budgetImportRow, budgetCatTotals, budgetNetOf, budgetTakeHome, budgetPlanned, budgetMonthSwitch, budgetYearAggregate, budgetShare`), 67 vectors total, generated by the budget section of `scripts/gen_vectors.mjs` and verified by the budget section of `scripts/verify_mirror.py`. `Packages/BloomCore/Tests/BloomCoreTests/BudgetTests.swift` asserts the combined budget vector count is at least 40.

## Contracts v3 (2026-07-08, approved additions and deviations)

Ten items, confirmed by Josiah 2026-07-08. Decisions D8 through D12 first, then full technical detail for the areas that need it. Where this layer supersedes v1 or v2 text above, the supersession is also marked inline at the point it occurs (the tab registry, the frozen view-name list, and the theme token count).

### Decision log v3 (2026-07-08)

All of D8 through D12 below are confirmed by Josiah, 2026-07-08.

- **D8**, resource bundling. Audio and font resources are bundled via XcodeGen sources discovery (`project.yml`'s `sources: - path: App` entry, not a separate `resources:` key), so files under `App/Resources` are automatically assigned to the Copy Bundle Resources build phase. A CI inspector gate (owner worker-scaffold) asserts the built `.app` contains exactly 13 tap and event mp3 files (`clear, easteregg, equals, error, modeswitch, operator, startup, success, tap1, tap2, tap3, tap4, tap5`, all present today at `App/Resources/Sounds/*.mp3`) and exactly 4 ttf files, one per `UIAppFonts` entry (`Quicksand, PlayfairDisplay, PlayfairDisplay-Italic, GreatVibes`, per `project.yml` and the v1 Scaffold registry above). The gate fails the build if either count is wrong, and runs on every CI build (test.yml and release.yml).
- **D9**, `ListsStore` adopts the HTML `bloom_lists` shape with a one-time migration from the legacy `bloomShopLists` shape. Full detail in the ListsStore v3 section below.
- **D10**, Liquid Glass is deferred to v1.1. No v1.0 code should adopt `.glassEffect` or related Liquid Glass materials; this matches the Parity Matrix Parking Lot entry already recorded by the docs worker (`docs/parity/PARITY_MATRIX.md`).
- **D11**, v1.0 ships TestFlight-only. No App Store Connect public listing, marketing page, or public release for v1.0; `fastlane/Fastfile`'s `upload_testflight` lane (which runs `pilot`) is the sole release path. Note for worker-scaffold: the v1 Scaffold registry above names the release step `bundle exec fastlane pilot_upload`, but the lane actually defined in `fastlane/Fastfile` today is named `upload_testflight`; reconcile the name in release.yml or the Fastfile so the two agree.
- **D12**, date celebrations. Full detail in the Celebrations section below.

Vectors.json is not extended in this v3 layer. None of D8 through D12 add new `contracts/vectors.json` keys; a future contracts revision should propose coverage for `ShareCodec`, `FundDefaults`, `Celebrations`, and the lists migration if worker-core and the test harness need it.

### Tab Registry v3 (supersedes the v2 seven-tab registry)

`BloomTab` (`App/Views/Root/BloomTab.swift`, currently `calc, proj, lists, kitchen, tools, budget, music`) becomes exactly five cases, in this order: `calc, proj, budget, kitchen, more`. `BloomTabBar` renders these five per Apple's five-tab HIG ceiling.

New frozen view names (finance-ui, `App/Views/Root/**`): `MoreView`, a designed hub grid holding Lists, Music, Tools, Sound Studio, Theme editor, and Credits; `ShareSheetView`, the global share and import sheet built on `ShareCodec` below. `ThemeEditorView` (already implemented and wired into `RootView`'s pencil-icon sheet, but never added to the frozen registry in v1 or v2) is retroactively frozen here too, also finance-ui, `App/Views/Root/**`.

`ListsView, MusicView, ToolsView, SoundStudioView, CreditsView` keep their existing names, file paths, and delight-ui ownership exactly as frozen in v1. Only their navigation route changes: they are no longer top-level tab destinations, they are reached by tapping their tile in `MoreView`'s hub grid.

`HistoryOverlay` is unchanged: still an overlay, still reached from the header, not part of this reshuffle.

Ownership call: `MoreView` and `ShareSheetView` are assigned to worker-finance-ui under `App/Views/Root/**` rather than worker-delight-ui, because `App/Views/Root/**` already owns the tab bar and header that these two views extend (`BloomTabBar.swift`, `RootView.swift`'s header icon row). This is an A02 contracts judgment call, not something Josiah specified directly; flag it for review if a build worker disagrees.

### ShareCodec (frozen, new BloomCore API, owner worker-core)

Source spec: the global share and import IIFE, `Bloom Calculator (all-in-one).html:3615-3896`. Sub-citations below.

```swift
public enum ShareTab: String, Codable, Sendable { case calc, projGrow, lists, kitchenConvert, recipe, budget, chords, tools, history }
public enum ShareCodec {
    public static func exportCalc(display: String, expression: String, memory: Double) -> String
    public static func exportProjGrow(principal: Double, monthly: Double, years: Double, ratePct: Double, fundName: String, futureValue: Double, contributed: Double, growth: Double) -> String
    public static func exportLists(title: String, rows: [ShopRow], total: Double) -> String
    public static func exportRecipe(name: String, serves: String, time: String, ingredients: [String], steps: [String], notes: String) -> String
    public static func exportChords(chordText: String, tempo: Int) -> String
    public static func parse(_ text: String) -> ShareImport?
}
public enum ShareImport: Equatable, Sendable { case budget(BudgetDB), projGrow(principal: Double, monthly: Double, years: Double, ratePct: Double), chords(text: String, tempo: Int?), list(title: String?, rows: [ShopRow]), recipeHint, calcResult(Double) }
```

**CORRECTED-FROM-BRIEF** (`exportCalc`). The brief froze `exportCalc(display:expression:)`, two parameters. HTML `exCalc()` (L3629-3636) also reads `txt('memVal')` and appends a `\n(memory: {value})` line whenever the memory value is not the string `'0'`. `CalcStore.memoryValue: Double` already exists in the App layer (`App/Views/Calc/CalcStore.swift:8`, backing M+/M-/MC/MR), so the memory line is a real, currently-unshared feature, not dead code. Corrected signature above takes a third parameter, `memory: Double`; appends `"\n(memory: " + Formatters.plain(memory) + ")"` when `memory != 0`, matching the HTML's non-zero check. Main line behavior otherwise verified exact: when `expression` is empty or a single space (`CalcStore.expression`'s own default is `" "`, a strong match), output is `"Result: " + display`; otherwise output is `expression + " " + display`.

**CORRECTED-FROM-BRIEF** (`exportRecipe`). The brief froze `exportRecipe(name:serves:lines:)`, three parameters. HTML `exKitchen()`'s recipe branch (L3695-3711) actually needs six independent inputs: name, serves, a separate time/duration field, an ingredients list (bulleted), an optional numbered steps list, and optional free-text notes; `App/Views/Kitchen/RecipePanel.swift`'s `RecipeWritePanel` already carries exactly these six as separate `@State` (`name, serves, time, ingredients, steps, notes`), independent confirmation that `lines: [String]` cannot carry the real shape. Corrected signature above: `exportRecipe(name:serves:time:ingredients:steps:notes:) -> String`. Behavior, transcribed from L3695-3711: if `name` is empty and `ingredients` has no non-empty entries, return the fixed fallback text `"Nothing to share yet - write a recipe on the Recipe tab first."` under the `Kitchen` header (the source HTML renders the joiner here as an em dash; shown as a hyphen in this document only to keep the no-em-dash house rule, the copy is otherwise verbatim). Otherwise: header is `head('Recipe') + (name or "Untitled recipe")`; unlike every other export function, the recipe branch does not call `nowLine()`, there is no date line; append `" (serves X, Y min)"` when either `serves` or `time` is non-empty (comma-joined, parens omitted entirely when both are empty); blank line then `INGREDIENTS` then one `"- " + ingredient` line per entry (source uses a bullet glyph, not a hyphen; either is acceptable here as long as it is consistent); when `steps` is non-empty, blank line then `STEPS` then `"N. " + step` per entry (1-indexed); when `notes` is non-empty, blank line then `NOTES` then the notes text; trailing `\n#hannahs-recipe-v1`.

Behavioral note, `exportProjGrow` (no correction, confirmed against L3641-3648): the "Projected value..." line is conditional in the HTML, only shown once a calculation has actually run (`vis('pResult')`). The frozen signature takes `futureValue`, `contributed`, and `growth` as non-optional `Double`, so the calling UI is responsible for only invoking `exportProjGrow` after a real calculation exists; there is no sentinel value in this signature for "not yet calculated."

The five share tags, verbatim: `#hannahs-proj-v1` (L3648, only on the `grow` projection mode), `#hannahs-list-v1` (L3681), `#hannahs-recipe-v1` (L3710), `#hannahs-budget-v1` (L3734, base64 JSON `{k, m}` payload, already frozen as `BudgetShare` in the v2 Budget section above), `#hannahs-chords-v1` (L3738).

Untagged exports, verbatim from `buildExport()`'s dispatch (L3762-3775) and `exProj`'s mode branches (L3637-3667): `calc`, kitchen `convert` mode, `tools`, `history`, and the five non-`grow` projection modes (`retire, match, real, compare`, and the final `else` branch, Rule of 72). Only the `grow` projection mode is tagged; `ShareCodec` does not expose export functions for the untagged surfaces beyond `exportCalc` itself (untagged, but still has a frozen function), consistent with the given API list.

Parse dispatch order, verbatim from `importBtn`'s click handler (L3883-3895): `#hannahs-budget-v1` first (delegates to `BudgetShare.parse`, wraps as `.budget`), then `#hannahs-proj-v1` (wraps as `.projGrow`), then `#hannahs-chords-v1` (wraps as `.chords`), then list detection, which is the tag OR the bullet grammar test regex `/[•\-\*]\s*[\d.]+\s*[x×]/` (L3890, a cheaper pre-check, distinct from the full per-row regex below) (wraps as `.list`), then `#hannahs-recipe-v1` (returns `.recipeHint` only; the HTML sets a fixed hint message, `"Recipes travel as text - paste the ingredients into Kitchen › Recipe."` (hyphen substituted for the source em dash here too), and returns immediately without attempting any import; `ShareCodec.parse` must do the same, callers must not try to auto-import a recipe), then the trailing calc fallback (`importCalc`, L3873-3882, regex `/=\s*([\-\d.,]+)\s*$/m` against the last `= number` line, wraps as `.calcResult`).

List row parsing, verbatim from `importList` (L3812-3831): full per-row regex is at L3814. Deliberate exception to this document's no-em-dash rule, noted explicitly rather than silently broken: the regex's separator character class matches either a hyphen or a literal em dash (`[—\-]{1,2}`), so collapsing it to a hyphen-only citation would misrepresent what the pattern actually matches, exactly the kind of "trust the file over the prose" case this task called out. Transcribed exactly: `/^\s*[•\-\*]\s*([\d.]+)\s*[x×]\s*(.+?)(?:\s*[—\-]{1,2}\s*\$?([\d.,]+))?\s*$/`, matching lines like `"• 2 x item"` or `"- 3 × item — $5.00"`; capture group 1 is qty (default 1 if unparseable), group 2 is trimmed name, group 3 is optional amount (empty string, not zero, when absent, matching the HTML's `''` sentinel; `ShopRow.amount` is `Double` in the frozen struct below, so `ShareCodec.parse`'s Swift representation should treat "amount absent" as `0`, there is no room for a `Double` sentinel string in the frozen shape). Lines that do not match the row regex are checked against a second regex, a title-recovery pattern matching the export header's `"{title}" + separator + "{Month Day, Year}"` line (source separator is a dash-like glyph between two runs of whitespace; not reproduced literally here to keep this document's no-em-dash rule), to recover the list title; first match wins, only used when a title has not already been recovered. Returns nil (no import) when zero rows matched.

Cross round-trip requirement (as given): a Swift export must be parseable by the JS import logic and vice versa; byte-identical text is not required except for the five tag lines themselves. `BudgetShare` (already frozen in v2) remains the budget payload codec; `ShareCodec.parse` delegates budget-tagged payloads to it and wraps the result as `.budget`.

### Projection reopen (fills a v1 gap, supersedes nothing)

```swift
extension ProjectionStore {
    public func reopen(_ entry: HistoryEntry)
}
```

Frozen `extra` keys, transcribed from the only place that writes `type: "proj"` history today, `App/Views/Projection/GrowPanel.swift:151-161` (`ProjectionStore.swift` itself currently has no history-writing or reopen code): `principal` (the raw `principalText` field string, for example `"10000"`), `monthly` (the raw `monthlyText` field string), `years` (`String(Int(years))`, a whole-number string), `ratePct` (`Formatters.plain(rate)`). All four values are `String`, matching the frozen `HistoryEntry.extra: [String: String]` shape exactly.

Gap versus the HTML: the HTML's equivalent history write (`L2274`, `addHistory({...extra:{inputs:{P,PMT,years,fundIdx,rate,name}}}))`) nests six fields under a single `inputs` object, including `fundIdx` and the fund `name`. The Swift `extra` dictionary is flat (a constraint already frozen in v1, `HistoryEntry.extra: [String: String]` cannot nest), and `GrowPanel` already only writes 4 of those 6 today, `fundIdx` and `name` are dropped. `reopen(_:)` can therefore restore `principal`, `monthly`, `years`, and `ratePct`, but cannot re-select the originating fund by identity, only a future implementation choosing to match `ratePct` against `ProjectionStore.funds` by rate would get close, and that would be a heuristic, not an identity match. This is a real, pre-existing gap in the App layer, not something this contract can silently fix by inventing a `fundIdx` key that nothing currently writes.

Implementation note (not a frozen signature, flagged for whoever builds this): `principal, monthly, years` are local `@State` on `GrowPanel`, not stored on `ProjectionStore` today. `reopen(_:)` will need a bridging `@Observable` property (for example a `pendingReopen` value) that `GrowPanel` reads on appear or on change, since `ProjectionStore` cannot reach into another view's `@State` directly.

### FundDefaults (new BloomCore API, owner worker-core)

```swift
public enum FundDefaults {
    public static func funds() -> [Fund]
}
```

Values, transcribed from `Bloom Calculator (all-in-one).html:2197-2202`: Conservative 4%/yr, Balanced 6%/yr, Growth 8%/yr, Aggressive 10%/yr. These match `ProjectionStore.swift`'s current `private static let defaultFunds` literal exactly (`App/Views/Projection/ProjectionStore.swift:37-42`); no correction needed, this is a straight confirm-and-relocate. `ProjectionStore.defaultFunds` must stop hardcoding these four `Fund` literals and call `FundDefaults.funds()` instead; the App-layer literal is the duplication this contract retires. Note: `Fund.id` is `UUID` per v1, so `FundDefaults.funds()` mints fresh UUIDs on every call; callers should invoke it once (for example inside `ProjectionStore.init()`, exactly where the literal lives today) rather than repeatedly, to keep fund identity stable across a session.

### ListsStore v3 shape (D9)

Source spec: `Bloom Calculator (all-in-one).html:2278, 2313-2328` (`saveList`, `reopenList`, and the `lists` array itself).

HTML truth, transcribed: `bloom_lists` in `localStorage` holds an array of objects shaped exactly `{id, ts, title, rows, total}`, where `id` is `Date.now()+Math.random()` (a JS number, not a string), `ts` is `Date.now()` (epoch milliseconds), `title` is a trimmed string defaulting to `"Untitled list"`, `rows` is an array of `{name, qty, amount}` (`qty` defaults to `1` when empty or null, `amount` defaults to `0` via `parseFloat(r.amount)||0`), and `total` is the precomputed sum of `qty * amount` across rows.

Frozen BloomCore model:
```swift
public struct ShopRow: Codable, Equatable, Sendable {
    public var name: String
    public var qty: Double
    public var amount: Double
}
public struct ShopList: Codable, Equatable, Identifiable, Sendable {
    public var id: String
    public var ts: Date
    public var title: String
    public var rows: [ShopRow]
    public var total: Double
}
```

`id: String` versus the HTML's numeric id: the HTML's `Date.now()+Math.random()` scheme is a browser-localStorage convention with no shared runtime with this iOS app, there is no literal shared storage to interoperate with, so `id` is a fresh Swift-generated `String` (for example `UUID().uuidString`), consistent with `HistoryEntry.id: String` already frozen in v1. This is not a correction, the brief's given `id: String` stands; this note only exists so nobody tries to force a `Double` id to match the HTML byte for byte.

`ts` millisecond strategy: `JSONStore` (`Packages/BloomCore/Sources/BloomCore/Persistence.swift`) uses a bare `JSONEncoder()`/`JSONDecoder()` with no custom `dateEncodingStrategy`, so today every frozen `Date` field (including `HistoryEntry.ts`) encodes via Foundation's default `.deferredToDate`, seconds since the 2001 reference date, not epoch milliseconds. Changing `JSONStore`'s shared encoder and decoder to `.millisecondsSince1970` would silently change `HistoryEntry.ts` and every other existing persisted `Date` field too, an unacceptable regression against frozen v1 behavior. `ShopList` must therefore implement custom `Encodable`/`Decodable` conformance itself, not rely on `JSONStore`'s shared strategy, so that `ts` specifically round-trips as a milliseconds-since-1970 JSON number, matching the HTML's `Date.now()` shape, while every other frozen type keeps its current encoding untouched.

`StoreKey` gains `case lists = "bloom_lists"` (raw value matches the JS `localStorage` key exactly, mirroring how `budget2` matches `BKEY2` in the v2 Budget section above).

Migration rule (D9), on first launch only, checked once: if `bloom_lists` (the new key) is absent and `bloomShopLists` (`StoreKey.shopLists`, the existing key backing today's `App/Views/Lists/ListsStore.swift`) is present, convert every old `ShopList` to the new shape and write it under `bloom_lists`; `bloomShopLists` itself is left untouched (no delete, no rewrite), so the migration is safe to re-run and there is no destructive step. Field mapping, verified against the current `App/Views/Lists/ListsStore.swift` model (`ShopListRow{id: UUID, name, qty, unitPrice, checked}` / `ShopList{id: UUID, title, rows, createdAt: Date}`):
- `id`: new `String` id is `old.id.uuidString`.
- `ts`: `old.createdAt` (direct `Date` carry-over, no unit conversion needed in Swift, only the JSON encoding differs as noted above).
- `title`: direct carry-over.
- `rows`: `old.rows.map { ShopRow(name: $0.name, qty: $0.qty, amount: $0.unitPrice) }`, `unitPrice` becomes `amount` exactly as specified.
- `checked`: dropped, no equivalent field in `ShopRow`.
- `total`: computed fresh as `rows.reduce(0) { $0 + $1.qty * $1.amount }`, matching both the HTML's `total` definition and `ShopListRow.lineTotal`'s existing formula (`qty * unitPrice`); not carried over from any old stored value, the old model has no `total` field, it is a computed property today.

Not addressed here (flagged, not solved): `ListsStore.reopen(from:)` (`App/Views/Lists/ListsStore.swift:98-103`) currently parses `entry.extra["listId"]` as a `UUID` string. Once lists move to the new `String` id shape, that reopen path needs a matching update; this contract does not freeze that change because the brief did not ask for it, flagging it so it is not lost.

### Design tokens v3

Source spec: `Bloom Calculator (all-in-one).html:12-26` (root vars) and the motion table below, verified against every `@keyframes`/`animation:` occurrence in the file, not only L84-210 (several tokens are reused at other line ranges with different durations, noted where relevant).

Radius scale, verbatim from L20 (`--radius:22px; --radius-lg:24px; --radius-md:16px; --radius-sm:12px; --radius-pill:999px;`): `radius` stays `22` (unchanged, already frozen). Four new tokens: `radiusLg` `24`, `radiusMd` `16`, `radiusSm` `12`, `radiusPill` `999`. This also retires the guidance at `contracts/theme-tokens.md:36-39`, which told workers to hardcode these four rather than treat them as tokens; that file is read-only reference for this agent and is not edited here, flag it for a companion update.

Shadow and ring, verbatim from L17-24: `sh1` is unchanged (already frozen, static across all four presets, `0 1px 2px rgba(66,21,39,.10),0 1px 1px rgba(66,21,39,.06)`). Two new tokens: `sh2` = `"0 10px 26px -14px " + shadow` and `sh3` = `"0 26px 60px -24px " + shadow`, both parameterized on the existing per-preset `shadow` token (so `sh2`/`sh3` vary by theme exactly as `shadow` already does; only the blur, spread, and offset numbers are fixed). One new token `ring` = `color-mix(in srgb, primaryStrong 28%, transparent)`; SwiftUI has no direct `color-mix` equivalent, so the Swift-side translation is `primaryStrong` at 28% opacity (mixing any color at X% into fully transparent is equivalent to that color at X% alpha under standard alpha compositing), so `ring` also varies by theme through `primaryStrong`.

ThemeSpec token count: 16 (v1/v2) plus these 7 (`radiusLg, radiusMd, radiusSm, radiusPill, sh2, sh3, ring`) equals 23 total, cross-referenced inline in the UI registry section above.

Motion table, verified against every occurrence in the HTML, not just L84-210:
- `viewIn`, `cubic-bezier(.22,1,.36,1)`, used at both `.35s` (`.tool-title.pop .tt-name`, L82) and `.45s` (`.view`, L84; also `.kpanel.active` at `.4s`, L275, and `.histscreen-inner` at `.4s`, L332). Brief's `0.35-0.45s` range confirmed exactly.
- `ripple`, `.6s ease-out`, L111-113. Confirmed exactly.
- `histIn`, `cubic-bezier(.22,1,.36,1)`, used at `.5s` (`.hitem`, the history list, L172) and `.45s` (`.lrow`, list rows, L251-252; `.kr-card`, recipe visualize cards, L295-296). Brief's `0.45-0.5s` range confirmed exactly. Per-index stagger is `0.04s`, confirmed at three separate call sites, all identical: list rows (`row.style.animationDelay=(i*0.04)+'s'`, L2297), recipe cards (`card.style.animationDelay=(i*0.04)+'s'`, L2466), and history items (`el.style.animationDelay=(idx*0.04)+'s'`, L2538).
- `spin`, `6s linear infinite`, L196-197 (toast flower icon). Confirmed exactly.
- `sheetUp`, `.4s cubic-bezier(.22,1,.36,1)`, L207-210. Confirmed exactly.
- **CORRECTED-FROM-BRIEF** (`fade`). Brief gave `0.18-0.5s ease`. Actual usages span wider: `.18s` (context-menu backdrop, L1001), `.3s` (modal backdrop L204 and the fullscreen history screen L326), `.5s` (poem overlay backdrop, `.poemwrap.show`, L522), and `.6s` (splash screen backdrop, `.splash.show`, L1850, separate from and in addition to its own `bloomIn` flower animation). Corrected range: `fade` is `ease`, and spans `0.18s` to `0.6s` depending on which surface is fading, not `0.18-0.5s`.
- `poemIn`, `.85s cubic-bezier(.22,1,.36,1)`, L525, 529. Confirmed exactly; brief omitted the easing curve, filled in here (same signature bezier as `viewIn`/`histIn`/`sheetUp`/`bloomIn`).
- `poemLine`, `1s cubic-bezier(.22,1,.36,1)` per line, base delay `0.35s` plus `0.7s` per line index (`p.style.animationDelay=(0.35+i*0.7)+'s'`, L2778). Confirmed exactly; easing curve filled in, brief omitted it, same signature bezier again.
- `revealPulse`, `2.8s ease-in-out infinite`, opacity keyframes `0%`/`100%` at `.72` to `50%` at `1`, L538-540. Confirmed exactly.
- `moreIn`, `.8s cubic-bezier(.2,.7,.3,1)`, L543-544. Confirmed exactly. Naming collision warning: this token is the HTML's existing entrance animation for the easter-egg poem overlay's "reveal more" content block (`.poem-more.show`), it has nothing to do with the new `more` tab and hub introduced in the Tab Registry v3 section above. Both now share the English word "more"; do not assume the animation was built for the hub.
- `bloomIn`, `1.1s cubic-bezier(.22,1,.36,1)`, L1852-1853 (splash screen flower). Confirmed exactly.
- `rollNumber`, `750ms`, cubic ease-out (`1-Math.pow(1-t,3)`, L2233-2236). Confirmed exactly, matches the JS `rollNumber()` easing formula precisely.

### KeyChords

Source spec: `Bloom Calculator (all-in-one).html:2917-2989` (the `BloomKeyChords` IIFE), L2975-2978 (the `BloomKeyChords` object, `setKeyChords`, `toggleKeyChords`, `restoreKeyChords`), and L2828-2829 (routing from `playMapped`).

`MusicStore` (`App/Views/Music/MusicStore.swift`) gains a new stored property: `var playOnKeys: Bool`. "The loaded chord list" is the store's existing `chords: [ChordVoice]` property, no new type needed.

```swift
extension MusicSynth {
    func chordVoicing(forDigit digit: Int) -> [Double]?
}
```
`chordVoicing(forDigit:)` lives on the synth side (`App/Audio/MusicSynth.swift`) per the brief; not `public`, matching every other member of this App-layer type. It answers `nil` when no chords are loaded; otherwise picks chord index `((digit % count) + count) % count` against the currently loaded chord set (kept in sync with `MusicStore.chords`/`transpose` whenever they change), and returns each note's frequency via `440.0 * pow(2.0, (Double(midi) - 69.0) / 12.0)`, the exact formula `MusicSynth.playChord` and the HTML's `freq(m)` (L2956) already use. This mirrors the HTML's `window.BloomKeyChords.play(d)` (L2975): `var i=((d%songs.length)+songs.length)%songs.length, c=songs[i];` then plays `nT(c)` (the chord's notes plus the current transpose).

Persistence: `StoreKey` gains `case keychords = "bloom_keychords"`. JSON shape, verbatim from `setKeyChords`/`restoreKeyChords` (L2976, L2978): `{"on": Bool, "text": String}`, `on` is the active flag, `text` is the last-loaded chord text (`el('mzText').value`), restored by re-running `load()` on the text and re-enabling only if `on` was true and `text` was non-empty.

Routing: calculator digit taps route to chord voicings only for digit keys (HTML's `/^d[0-9]$/` test, L2829), never for operators, dot, equals, or clear; this replaces the rotating `tap1`-`tap5` tap sound for digits only, when `playOnKeys` (the HTML's `BloomKeyChords.active`) is true.

**CORRECTED-FROM-BRIEF** (master sound toggle and keychords-on-digit-tap routing). The brief states "Master sound toggle does NOT gate music playback, matching the HTML." That is true for the Music tab's own manual playback, the chord pads and the Play button call `chord()` directly (L2965, L2971, L2973), with no `soundsOn` check anywhere in that path. It is not true for the specific behavior this section is about, digit taps routing to chord voicings. The HTML's `playMapped(id,gain)` (L2828-2829) reads:
```js
function playMapped(id,gain){ if(!soundsOn) return;
    if(window.BloomKeyChords && window.BloomKeyChords.active && /^d[0-9]$/.test(id)){ window.BloomKeyChords.play(+id.slice(1)); return; }
```
`if(!soundsOn) return;` is the first line of the function and runs before the `BloomKeyChords` branch is ever reached, and `playMapped` is the only call site that triggers `BloomKeyChords.play` from a calculator key tap (both the on-screen `keys` click handler, L2843, and the physical-keyboard `keydown` handler, L2844-2854, which has its own redundant `if(!soundsOn) return;` at the very top too, L2845). So when the master sound toggle is off, digit taps produce no sound at all today in the HTML, neither the tap sound nor the chord. Swift's `playOnKeys`-gated digit routing should replicate this: gated by the master sound toggle exactly like every other tap sound, even though the separate Music-tab manual playback is not.

### Celebrations (D12, new BloomCore API, owner worker-core)

```swift
public struct Celebration: Codable, Equatable, Sendable {
    public let id: String
    public let month: Int
    public let day: Int
    public let year: Int?
    public let kind: String
    public let title: String
    public let lines: [String]
}
public enum Celebrations {
    public static func all() -> [Celebration]
    public static func due(on date: Date, calendar: Calendar, shown: Set<String>) -> Celebration?
}
```

Entries, frozen:
- `id: "splash-0316"`, `month: 3, day: 16, year: nil` (annual), `kind: "splash"`. Title `"Hannah"`, lines `["My Forever Love"]`, matching `SplashController`'s existing defaults exactly (`App/Views/Overlays/SplashOverlay.swift:8-9`, `name = "Hannah"`, `subtitle = "My Forever Love"`); no placeholder needed, this copy already exists and ships today via `SplashController.trigger()`'s default arguments.
- `id: "note-0725"`, `month: 7, day: 25, year: 2026`, `kind: "note"`. Copy is a placeholder, see below. **JOSIAH-APPROVAL-REQUIRED.**
- `id: "note-1205"`, `month: 12, day: 5, year: 2026`, `kind: "note"`. Copy is a placeholder, see below. **JOSIAH-APPROVAL-REQUIRED.** Context for whoever finalizes this: the existing easter eggs already tied to the `12/5/26` calculator sequence (`in-unity, a-good-feeling, acceleration, no-condemnation` in `Packages/BloomCore/Sources/BloomCore/Resources/eggs.json`) describe it as a wedding date ("I just got a good feeling about this wedding", "on the Fifth of December, and our love shall multiply"); the placeholder below assumes that context, but Josiah should confirm or correct it.

Copy placeholder rule, both entries below are placeholders, not final copy, each marked **JOSIAH-APPROVAL-REQUIRED**:
- `note-0725`: title `"[PLACEHOLDER] A little celebration"`, lines `["[PLACEHOLDER] Today's one of the good ones. Josiah: tell us what makes 7/25 worth marking, and we'll write the real line."]`.
- `note-1205`: title `"[PLACEHOLDER] The big day"`, lines `["[PLACEHOLDER] However today goes, it's the one you've been counting toward. Josiah: confirm this is the wedding date before shipping, and replace with real copy."]`.

Latch mechanism: shown ids persist under `StoreKey case celebrations = "bloom_celebrations"` as a `Set<String>` (or equivalent). Key used per celebration: when `year == nil` (the annual `splash-0316` case), the key is `"\(id)-\(year of the date being checked)"`, so it re-latches, and can fire again, every new calendar year; when `year` is set (both `note` entries), the key is just `id`, since those are one-time-only occurrences that never need to repeat.

`due(on:calendar:shown:)` behavior: for each `Celebration` in `all()`, compare `calendar`'s month and day components of `date` against `celebration.month`/`celebration.day`; skip if either does not match; if `celebration.year` is set, skip unless it also equals `date`'s year component; compute the shown-key per the latch rule above, skip if `shown` already contains it; return the first remaining match, `nil` if none.

Rendering: `kind == "splash"` renders via the existing `SplashOverlay`/`SplashController` (`title` becomes the displayed name, first `lines` entry becomes the subtitle). `kind == "note"` renders via the existing `ToastHost`/`ToastCenter` (`title` becomes the toast title, `lines` joined becomes the message).

Hard boundary (do not violate): `due(on:calendar:shown:)` must never be called from `CalcStore`'s key-press path, or from anywhere `EasterEggs.match(sequence:)` is checked. Celebrations are a calendar-date check (today's real-world date, checked once per app foreground or launch), completely independent from the ten frozen easter eggs, which trigger on typed calculator sequences (`4÷16÷25`, `12-5-26`, and the rest, per `eggs.json`). Both mechanisms may legitimately fire on the same real day (for example, typing `12/5/26` on the calculator in any year triggers the `no-condemnation` egg regardless of what today's date is, while the `note-1205` celebration only fires when today actually is December 5, 2026); neither may suppress or intercept the other.

### Celebrations v3.1 correction (2026-07-08, Josiah, supersedes the calendar design above)

Josiah clarified the trigger: "these notes are when she adds, subs, divs, multis these numbers together (Eg 3+16+26)". Celebrations therefore fire from typed calculator sequences through the existing easter-egg pipeline, not from the calendar. The entire calendar-based API above (`Celebration` struct, `Celebrations.due(on:calendar:shown:)`, `StoreKey case celebrations`) is WITHDRAWN and must not be implemented. No new StoreKey. No latch: like every egg, these re-fire whenever the sequence is typed.

Design, additive only. The ten frozen eggs in `eggs.json` stay byte-identical; new entries append after them. The `Egg` schema is unchanged; `kind` now takes a third value `splash` alongside `poem` and `toast` (the HTML's `checkEgg` already dispatches `kind === 'splash'` to `showSplash`, L2092; it simply has no such entry today). Swift dispatch: the egg-hit path adds a `splash` branch that presents `SplashOverlay` via `SplashController.trigger()` with its existing defaults (name `Hannah`, subtitle `My Forever Love`, petal shower). Owner: worker-core for `eggs.json` additions and any `EasterEggs` touch, A26 for the dispatch branch and overlay wiring, A30 for vectors (match plus near-miss for every new sequence; the 24 existing egg vectors untouched).

New entries, frozen pending copy approval:
- `anniversary-splash`, `kind: splash`, dateLabel `3 · 16 · 26`, triggers: `3÷16÷26`, `3/16/26`, `3+16+26`, `3×16×26`, `3*16*26`, `3−16−26`, `3-16-26` (glyph plus ascii variants, matching the existing eggs' convention). ASSUMPTION, JOSIAH-CONFIRM: he first said "wire it for March 16th, 2025", but the four `3/16/25` sequences are owned by the frozen poems (Never Divided and siblings) and first-match dispatch must not be disturbed; his own example used year 26, so the splash lives on the `3/16/26` anniversary sequences and typing `3/16/25` still gives the original poems.
- Four engagement toasts on the `7/25/26` sequences (engagement anniversary, confirmed 2026-07-08), one per operator, glyph plus ascii trigger variants each, `kind: toast`. Proposed copy, JOSIAH-APPROVAL-REQUIRED: `7÷25÷26` title `Undivided`, line `Engaged and inseparable since July 25, 2026.`; `7+25+26` title `A Perfect Addition`, line `The day forever got added.`; `7×25×26` title `Love Multiplied`, line `One question, infinite returns.`; `7−25−26` title `Nothing Taken`, line `She said yes, and nothing was ever subtracted.`
- `12/5/26`: NO new entries. The four frozen wedding poems (in-unity, a-good-feeling, acceleration, no-condemnation) already own those sequences and are the wedding celebration. Any extra wedding note would need a non-colliding sequence; decision left open and unscheduled.

### D13, mode-switch chord cycling (2026-07-08, Josiah, from v0.1.9 device testing; iOS-only divergence, documented)

When MusicStore holds a loaded chord progression, the tab-switch sound event plays the NEXT chord of the progression in written order (advancing an index, wrapping at the end) through MusicSynth, instead of modeswitch.mp3. With nothing loaded, modeswitch.mp3 plays exactly as before. The master sound toggle gates this like every mapped event. The Music tab must also carry an explicit Load button that parses the textarea into chord pads, matching the HTML's Load control (L1670-1695, IIFE L2917-2989); sample chips keep loading their progressions too.

### Sound parity note (item 10)

Confirmed accurate against the HTML, no correction needed: toggling master sound back on plays a `tap1` preview at gain `0.5` (`Bloom Calculator (all-in-one).html:2839`, `if(soundsOn) playSound('tap1',0.5);`). `SoundStudioView`'s option list (`KEYPAD`, `EVENTS`, `OPTIONS` in the HTML, L2881-2888) and `DEFAULT_MAP` stay frozen exactly as v2 defined them; this v3 layer makes no changes there.

Quick reference, `StoreKey` cases added this round: `lists = "bloom_lists"` (ListsStore v3), `keychords = "bloom_keychords"` (KeyChords), `celebrations = "bloom_celebrations"` (Celebrations).
