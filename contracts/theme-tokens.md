# Summit theme tokens

Adapted from Bloom's frozen 16-token registry (same token names and roles) using the
Summit Design System palette (`Summit/extracted/tokens/colors.css`). All five presets
are dark; `deep` is the light *headline* color on dark surfaces (the inverse of Bloom,
where it was the darkest ink), and `flowerCenter` is kept as a legacy key whose role is
now the amber "peak" accent.

Source of truth in code: `App/Theme/ThemeStore.swift` `presetTokens(for:)`.

## The 16 tokens (camelCase names)

| token (camelCase) | lake (default) | pine | cedar | granite | river |
|---|---|---|---|---|---|
| bg | `#12181D` | `#161A14` | `#1C1610` | `#14181B` | `#101917` |
| surface | `#1E262D` | `#232920` | `#2A211A` | `#21282D` | `#1D2926` |
| surfaceSoft | `#28333C` | `#2C3427` | `#362A1F` | `#2B343B` | `#26352F` |
| surface2 | `#232D35` | `#272E22` | `#302519` | `#262E34` | `#223029` |
| primary | `#6FA3C7` | `#7FA985` | `#C58757` | `#8AA5B5` | `#6FBCAC` |
| primaryStrong | `#4A7FA5` | `#5E8C61` | `#A9683F` | `#5B7482` | `#3E8E7E` |
| deep | `#C8DEEF` | `#CFE3CC` | `#E7C9A9` | `#C9D9E2` | `#BFE2D8` |
| text | `#E4EAEF` | `#E8EAE0` | `#EFE6DA` | `#E4EAEE` | `#E1EEEA` |
| muted | `#8FA0AD` | `#9AA692` | `#A8988A` | `#93A1AB` | `#8FA69E` |
| line | `#35424C` | `#3A4233` | `#453729` | `#37424A` | `#32443E` |
| flowerCenter | `#D9A441` | `#D9A441` | `#D9A441` | `#D9A441` | `#E0B04F` |
| good | `#5FBF84` | inherited | inherited | inherited | inherited |
| shadow | `rgba(0,0,0,.45)` | `rgba(0,0,0,.45)` | `rgba(0,0,0,.5)` | `rgba(0,0,0,.5)` | `rgba(0,0,0,.5)` |
| ripple | `rgba(255,255,255,.18)` | inherited | inherited | inherited | inherited |
| sh1 | `0 1px 2px rgba(0,0,0,.35),0 1px 1px rgba(0,0,0,.25)` | inherited | inherited | inherited | inherited |
| radius | `16` | inherited | inherited | inherited | inherited |

Notes:
- `radius` dropped from Bloom's 22 to 16 per the design system ("hewn, less soft").
- `flowerCenter` keeps its key for persistence/CONTRACTS compatibility; its UI label is
  "Summit peak" and its role is the amber accent (sun disc, gold details, pin tint).
- The app runs `.preferredColorScheme(.dark)` — the presets assume dark system chrome.

## The 12 editable tokens (custom theme editor)

Same order as Bloom; labels updated in `ThemeStore.editableTokenLabel`:

| order | camelCase token | human label |
|---|---|---|
| 1 | bg | Page background |
| 2 | surface | Card surface |
| 3 | surfaceSoft | Keys & panels |
| 4 | surface2 | Accent panels |
| 5 | primary | Ridge accent |
| 6 | primaryStrong | Strong accent |
| 7 | deep | Headlines |
| 8 | text | Main text |
| 9 | muted | Soft text |
| 10 | line | Borders |
| 11 | flowerCenter | Summit peak |
| 12 | good | Growth color |

`shadow`, `ripple`, `sh1`, `radius` remain non-editable.

## Font roles

| role | family | replaces (Bloom) | usage |
|---|---|---|---|
| body | Archivo | Quicksand | default body text, UI chrome |
| numbers / headings | Bitter (+ Italic) | Playfair Display | calculator display, headings |
| script | Rye | Great Vibes | wordmark, splash, egg titles |

Fetched at CI time by `scripts/fetch_fonts.sh` from pinned google/fonts raw URLs
(never committed): `Archivo.ttf`, `Bitter.ttf`, `Bitter-Italic.ttf`, `Rye-Regular.ttf`.
`project.yml` `UIAppFonts` and both CI workflows' bundle checks list these exact
filenames. All three families are SIL OFL (credited in CreditsView).
