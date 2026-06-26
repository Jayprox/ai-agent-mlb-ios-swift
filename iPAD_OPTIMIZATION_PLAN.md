# iPad Optimization Plan — v1.1

**Status:** Planning  
**Target Release:** v1.1 (post-v1.0 launch)  
**Device Support:** iPad Air 5th gen, iPad Pro 11", iPad Pro 12.9"

---

## Overview

Chalk That v1.0 is iPhone-optimized. v1.1 will add responsive iPad layouts to better utilize the larger screen while maintaining the core research/analysis experience.

---

## Key Changes

### 1. Navigation — Bottom Tabs → Adaptive UI
**iPhone (current):** TabView with 9 tabs at bottom
**iPad (new):** NavigationSplitView with sidebar

#### Implementation:
- Use `UIDevice.current.userInterfaceIdiom == .pad` to detect iPad
- Sidebar navigation on iPad: collapsible, shows all 9 tabs vertically
- Keep TabView on iPhone for consistency
- Preserve all functionality: Slate, Board, AI Board, Model, Predict, Scout, Chat, Picks, Settings

---

### 2. SlateView — Single Column → 2-Column Grid

**Current (iPhone):**
```
[Game Card]
[Game Card]
[Game Card]
...
```

**iPad:**
```
[Game Card] [Game Card]
[Game Card] [Game Card]
[Game Card] [Game Card]
...
```

#### Implementation:
- Use `LazyVGrid` with adaptive columns: `[GridItem(.adaptive(minimum: 320))]` on iPad
- Adjust card width: max ~350px per card on iPad
- Maintain 10-16px horizontal padding
- Single-column on iPhone (current behavior)

---

### 3. AIBoardView — Cards → Table Layout

**Current (iPhone):** Vertical cards (player name, market, odds, edge, confidence)

**iPad:** Horizontal table with columns:
```
Player Name | Market | Odds | Edge % | Confidence | Action
```

#### Implementation:
- Use SwiftUI Grid or custom table layout on iPad
- Sortable columns (tap header to sort by that column)
- Row striping (alternate light/dark backgrounds) for readability
- Keep card view on iPhone
- Tap row to expand details (modular/sheet)

---

### 4. BoardView — Responsive Content Area

**Current:** Fixed-width cards centered with padding

**iPad:**
- Increase max content width to 80% of screen
- 2-column layout for candidate cards if multiple streams exist
- Better use of horizontal space

#### Implementation:
- Conditional frame modifiers based on `horizontalSizeClass`
- Adjust card widths: max ~600px on iPad

---

### 5. PicksView — Grid Layout

**Current (iPhone):** Vertical list of pick cards

**iPad:** 
- Option A: Table layout (columns: Date, Game, Market, Pick, Odds, Result, Grade)
- Option B: 2-column grid of pick cards
- Include filter/sort controls at top

#### Implementation:
- Table preferred for better data density on iPad
- Sortable columns (Date, Grade, ROI)
- Filtering: by result (Won/Lost/Push), by market type

---

### 6. GameDetailView — Expand Details Pane

**Current:** Tabs (Overview, Lineup, Arsenal, Bullpen, Intel, Boxscore)

**iPad:**
- Left sidebar: team/game info + tab navigation
- Right pane: tab content (larger, more readable)
- Or: 2-column layout with game info on left, active tab content on right

#### Implementation:
- NavigationSplitView for game detail if depth allows
- Keep current tab structure, but expand content area

---

## Content Width Guidelines

| Device | Ideal Content Width | Notes |
|--------|-------------------|-------|
| iPhone | 100% (with 16px margin) | Current implementation |
| iPad | 80% of screen (max ~1000px) | Readable without scrolling horizontally |
| iPad Pro 12.9" | 70% of screen (max ~900px) | Sidebar + content split |

---

## Technical Approach

### Size Class Detection
```swift
@Environment(\.horizontalSizeClass) var sizeClass

var isIPad: Bool {
    sizeClass == .regular
}
```

### View Modifiers
Create reusable modifiers:
```swift
.adaptiveFrame(isIPad ? .wide : .narrow)
.adaptiveGridColumns(isIPad ? 2 : 1)
.adaptiveTableLayout(isIPad)
```

### Testing
- Xcode: iPad simulators (11", 12.9")
- Device: Test on actual iPad if available
- Landscape + Portrait orientations
- Split screen / slide-over multitasking (future nice-to-have)

---

## Priority Order

1. **High (Core Experience):**
   - Adaptive navigation (MainTabView)
   - SlateView multi-column
   - AIBoardView table layout

2. **Medium (Important):**
   - BoardView responsive spacing
   - PicksView table/grid
   - GameDetailView sidebar

3. **Low (Polish):**
   - Landscape orientation optimization
   - Multitasking support
   - Custom landscape layouts

---

## Production Issues to Address

As v1.0 usage generates feedback, capture issues here and prioritize for v1.1:
- See `PRODUCTION_ISSUES.md`

---

## Testing Checklist

- [ ] MainTabView sidebar renders on iPad
- [ ] All 9 tabs accessible and functional
- [ ] SlateView: games display in 2-column grid on iPad
- [ ] AIBoardView: table layout renders correctly
- [ ] Pick cards/table layout works on iPad
- [ ] Touch targets ≥ 44x44 on all buttons
- [ ] No horizontal scrolling on iPad (content fits width)
- [ ] Portrait and landscape orientations work
- [ ] Font sizes readable on larger screens
- [ ] Take iPad screenshots for App Store v1.1

---

## Rollout

**v1.0:** iPhone only (current)  
**v1.0.1+:** Bug fixes if needed before v1.1  
**v1.1:** iPad responsive + any production issues addressed  
**v1.2+:** Advanced features (landscape, multitasking)

