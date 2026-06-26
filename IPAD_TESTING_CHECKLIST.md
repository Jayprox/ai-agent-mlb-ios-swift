# iPad Testing Checklist — Chalk That v1.1 (iPad Release)

## Pre-Test Setup

- [ ] Build for iPad Air 5th gen (or iPad mini A17 Pro) in Xcode
- [ ] Test on both portrait and landscape orientations
- [ ] Verify device is set to Dark Mode
- [ ] Clear app cache before first test run

---

## Navigation & Layout

### Bottom Tab Bar (All Orientations)
- [ ] Tabs display at bottom (not sidebar)
- [ ] All 9 tabs visible: Slate, Board, AI Board, Model, Predict, Scout, Chat, Picks, Settings
- [ ] Tab switching is smooth
- [ ] Active tab highlight shows correctly (green for Slate)

### ScrollView Responsiveness
- [ ] Content expands to fill iPad width naturally (no left-aligned gap)
- [ ] No sidebar appears on iPad (forced .stack style)
- [ ] Landscape doesn't break layout
- [ ] Safe area respected (notch/home indicator)

---

## Slate Tab

### Game Cards
- [ ] Score displays correctly (KC 2, TB 13)
- [ ] Status shows correctly (FINAL, @, inning if live)
- [ ] Pitcher names display with **handedness (R/L)** ✨
  - Example: "Lugo R vs Legumina L"
- [ ] IL badges show if pitcher is injured
- [ ] Temperature displays (76°, 63°, etc.)
- [ ] **Wind info displays** (5 mph WSW, 6 mph WSW) ✨
- [ ] NRFI confidence displays (NRFI 67%, etc.)

### Missing Data (Expected Gaps)
- [ ] Venue NOT showing (backend issue — expected)
- [ ] Odds NOT showing (oddsMap empty — expected)
- [ ] Note these for backlog

### Game Tap
- [ ] Tap game card → detail view opens
- [ ] Detail view shows all tabs (Overview, Lineup, Arsenal, etc.)
- [ ] No crashes on detail view

---

## Board Tab

- [ ] Market tabs display (HR, Hits, K, Outs, Games)
- [ ] Candidates load and display
- [ ] Scrolling is smooth
- [ ] No layout shifts

---

## Model, Predict, Scout Tabs

- [ ] Content loads and displays
- [ ] Layout is responsive
- [ ] Scrolling works smoothly

---

## Picks Tab

### Pick Cards Display
- [ ] Pick information shows clearly
- [ ] **Pick line displays with market** ✨
  - Example: "OVER 18.5 K" (not just "OVER 18.5")
- [ ] P&L displays correctly
- [ ] Result badges (HIT, MISS, PENDING) show

### Functionality
- [ ] Can mark picks as hit/miss
- [ ] Can void picks
- [ ] Filter tabs work (ALL, 7D, 30D)

---

## General

### Performance
- [ ] App launches in <2 seconds
- [ ] Scrolling is 60fps (smooth)
- [ ] No lag when switching tabs
- [ ] Images load smoothly

### Dark Mode
- [ ] All text readable on dark background
- [ ] No contrast issues
- [ ] Colors match mockup (green for actions, red for warnings)

### Orientation
- [ ] Portrait mode works
- [ ] Landscape mode works (if applicable)
- [ ] Rotating device doesn't crash app
- [ ] Layout adapts smoothly

### Crashes
- [ ] No crashes on any screen
- [ ] Tapping all buttons/links doesn't crash
- [ ] Scrolling large lists doesn't crash

---

## Known Limitations (Document)

✋ **Expected to NOT see:**
- [ ] Pitcher ERA on Slate cards (waiting on backend `pitcherStatsMap`)
- [ ] Game-level odds (ML, O/U, RL) (waiting on backend `oddsMap`)
- [ ] Venue/stadium name (backend not returning)

---

## Sign-Off

| Item | Status | Notes |
|------|--------|-------|
| Navigation responsive | ⬜ | |
| Slate tab layout | ⬜ | |
| Slate cards complete | ⬜ | |
| Picks tab display | ⬜ | |
| Wind data showing | ⬜ | |
| Pitcher handedness showing | ⬜ | |
| No crashes | ⬜ | |
| Performance smooth | ⬜ | |

---

## Submission Checklist

- [ ] All tests pass
- [ ] No crashes found
- [ ] Known limitations documented
- [ ] Bundle display name: "Chalk That" ✓
- [ ] Version ready for App Store
- [ ] Screenshots updated (if needed)

