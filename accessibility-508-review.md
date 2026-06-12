# Accessibility / 508 review — Prop Scout MLB

Scope: SwiftUI accessibility audit across all 28 view files — VoiceOver
labels, Dynamic Type support, color contrast vs. the brand palette, and
minimum 44×44pt tap targets. Findings are grouped by category with
representative examples (not every occurrence is listed — the patterns
repeat across most views).

## 1. Dynamic Type — not supported (largest finding)

The entire app uses `.font(.system(size: N, ...))` with hardcoded point
sizes — found ~480 times across 28 files (e.g. `GameIntelView` 33,
`BoardCandidateCardView` 29, `GameOverviewView`/`ChatView` 27,
`SlateCardView` 26). Only one `.minimumScaleFactor` call exists in the whole
app (`GameBullpenView.swift:217`), and there is no `@ScaledMetric`,
`.dynamicTypeSize`, or `Font.system(.body)`-style relative font anywhere.

**Effect:** users who increase text size in iOS Settings (Larger Text /
Accessibility → Display & Text Size) see **zero change** — every label stays
fixed at its design-time pixel size. This is a Dynamic Type / "text
resizing" violation under WCAG 1.4.4 and Section 508, and a real barrier for
low-vision users.

**Recommendation:** A full conversion of every `.font(.system(size:...))`
call to scalable fonts (`.font(.system(.body, design: .monospaced))` +
`@ScaledMetric`, or relative sizing) would touch nearly every view file —
this is a large, mechanical-but-risky refactor given the dense, fixed-layout
card designs (many cards are tuned to exact pixel widths). Given the size,
I'd suggest treating this as its own follow-up effort rather than bundling it
into #101, possibly starting with the highest-traffic screens (Slate, Board,
Picks, Settings) and key text (body copy, not badges/labels in tight grids).

## 2. Color contrast — `brandTextDim` fails WCAG AA for small text

Computed contrast ratios against the brand palette (`Color+Brand.swift`):

| Pair | Ratio | WCAG AA (normal text, 4.5:1) |
|---|---|---|
| `brandText` (#f9fafb) on `brandBackground` | 18.6:1 | ✅ |
| `brandTextMuted` (#9ca3af) on `brandBackground` | 7.7:1 | ✅ |
| `brandTextDim` (#6b7280) on `brandBackground` | **4.0:1** | ❌ (needs 4.5:1) |
| `brandTextDim` on `brandSurface` (#161827) | **3.6:1** | ❌ |
| `brandRed` (#ef4444) on `brandBackground` | 5.2:1 | ✅ |
| `brandBlue` (#3b82f6) on `brandBackground` | 5.3:1 | ✅ |
| `brandGreen` / `brandAmber` on background | 8.5:1 / 11.7:1 | ✅ |

`brandTextDim` is used extensively at small sizes (9–13pt) for things like
the Settings footer, "void" pick action, timestamps, and secondary labels —
all of which fall short of the 4.5:1 ratio required for normal-size text
(it does clear the 3:1 bar for *large* text, 18pt+/14pt bold, but most uses
here are well under that).

**Recommendation:** Either (a) lighten `brandTextDim` slightly (e.g. to
something around `#7d8694`, which gets close to 4.5:1 on both background and
surface), or (b) reserve `brandTextDim` for large/bold text and switch small
secondary text to `brandTextMuted` (7.7:1, safe everywhere). Option (b) is
lower-risk since it's a per-usage swap rather than a palette-wide color
change that could affect other contrast-dependent UI.

## 3. Icon-only buttons with no VoiceOver label

Several controls are a bare SF Symbol with no text and no
`.accessibilityLabel`. VoiceOver will announce these only as "button" (or
the symbol's literal SF Symbol name in some cases), giving no indication of
what they do:

- **Close ("✕") button** — `WhyModalView.swift:53-59`. 26×26pt circle,
  no label. VoiceOver reads roughly "xmark, button."
- **Add to Picks ("+") buttons** — `ModelPickCardView.swift:131-137`,
  `PredictCardView.swift:63-69`, `AIBoardEdgeCardView.swift:119-125`,
  `BoardCandidateCardView.swift:209-215`. All `plus.circle.fill`, no label.
- **Log Pick ("+") toolbar button** — `PicksView.swift:225-231`.
- **Settings (gear) toolbar button** — `PicksView.swift:232-238`.
- **Send message button** — `ChatView.swift:178-182`,
  `arrow.up.circle.fill`, no label.
- **Grade buttons ("✓" / "✗")** — `PickCardView.swift:66-87`. These have a
  glyph as `Text`, so VoiceOver reads "check mark, button" / "cross mark,
  button" — better than nothing but not descriptive of the action (mark pick
  as hit/miss).

**Recommendation:** Add `.accessibilityLabel(...)` to each, e.g. "Close",
"Add to Picks", "Log a pick", "Settings", "Send message", "Mark pick as hit",
"Mark pick as miss". This is a small, low-risk, high-value fix — I'd
recommend including this in #101.

## 4. Tap targets below 44×44pt

Apple/WCAG recommend a minimum 44×44pt hit target for interactive controls.
Several controls are noticeably smaller:

- **WhyModal close button** — fixed `.frame(width: 26, height: 26)`
  (`WhyModalView.swift:57`).
- **Pick grade buttons ("✓"/"✗")** — fixed `.frame(width: 28, height: 28)`
  (`PickCardView.swift:73`, `84`).
- **"void" pick button** — no explicit frame; padding-only sizing at 9pt
  font (`PickCardView.swift:92-98`), likely well under 44pt tall.
- **Toolbar "+" / gear icons in Picks** — 16pt `Image(systemName:)` with no
  frame (`PicksView.swift:228-237`); actual hit area depends on
  `NavigationView` toolbar padding, but the visual target is small.

**Recommendation:** Add `.frame(minWidth: 44, minHeight: 44)` (or
`.contentShape(Rectangle())` with adequate padding) to these controls without
changing their visual size — the tappable area can be larger than the
rendered icon.

## 5. What's already fine

- Text contrast for primary/secondary text (`brandText`, `brandTextMuted`)
  against both background and surface colors is well above AA thresholds.
- Most buttons that combine an icon with a text `Label` (e.g. `TabView`
  items in `MainTabView`, "VIEW ALL", "Build Scout Slate", "Regenerate") are
  fine for VoiceOver — the text gives a clear accessible name automatically.
- No flashing/auto-animating content that would trigger seizure-related
  (WCAG 2.3.1) concerns.
- Dark-mode-only design (`.colorScheme(.dark)`) is a deliberate choice, not
  an accessibility issue by itself — iOS "Increase Contrast" and "Reduce
  Transparency" settings aren't specifically wired up, but nothing in the UI
  relies on transparency for legibility.

## Suggested scope for #101 (fixes)

Given the size of the Dynamic Type item, I'd suggest #101 cover the smaller,
contained fixes:

1. Add `.accessibilityLabel` to the icon-only buttons listed in §3.
2. Bump the tap targets in §4 to ≥44×44pt.
3. Swap `brandTextDim` → `brandTextMuted` for small (<18pt) text instances,
   or adjust the `brandTextDim` hex value — whichever you'd prefer.

Dynamic Type (§1) would be tracked separately as a larger follow-up given
its scope across the codebase.
