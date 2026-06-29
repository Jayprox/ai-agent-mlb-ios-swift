# Pitcher Splits Expansion: Home/Away + Day/Night Stats

## Overview
We want to expand the pitcher splits display on the Game Overview tab to include:
- Platoon splits (VS LHH / VS RHH) ✅ *Already implemented*
- **Home / Away splits** *(New)*
- **Day / Night game splits** *(New)*

## Current Implementation
✅ Platoon splits (VS LHH / VS RHH) displaying correctly with:
- AVG (batting average against)
- OPS (opponent OPS)
- K/9 (strikeouts per 9)
- BB/9 (walks per 9)

## New Splits Requested

### Home / Away Splits
Display pitcher stats when playing at home vs away:
- **ERA** (earned run average)
- **WHIP** (walks + hits per innings pitched)
- **IP** (innings pitched) — total sample size
- **K/9** (strikeouts per 9, optional)
- **BB/9** (walks per 9, optional)

### Day / Night Game Splits
Display pitcher stats in day games vs night games:
- **ERA**
- **WHIP**
- **IP** — total sample size
- **K/9** (optional)
- **BB/9** (optional)

## Proposed Response Shape

**Endpoint:** `/api/pitcher-splits/{pitcherId}`

**Updated response (add to existing):**

```json
{
  "pitcherId": 641793,
  "season": 2026,
  
  "vsLeft": {
    "avg": ".301",
    "ops": ".998",
    "k9": "4.3",
    "bb9": "3.2"
  },
  "vsRight": {
    "avg": ".231",
    "ops": ".663",
    "k9": "6.9",
    "bb9": "2.3"
  },
  
  "home": {
    "era": "6.15",
    "whip": "1.43",
    "ip": "45.1",
    "k9": "4.2",
    "bb9": "3.1"
  },
  "away": {
    "era": "6.15",
    "whip": "1.43",
    "ip": "45.1",
    "k9": "4.2",
    "bb9": "3.1"
  },
  
  "dayGame": {
    "era": "4.08",
    "whip": "1.23",
    "ip": "28.2",
    "k9": "3.8",
    "bb9": "2.9"
  },
  "nightGame": {
    "era": "6.22",
    "whip": "1.51",
    "ip": "46.1",
    "k9": "4.4",
    "bb9": "3.2"
  }
}
```

## Swift Model Updates Needed

```swift
struct PitcherSplits: Decodable {
    let pitcherId: Int?
    let season: Int?
    
    // Existing platoon splits
    let vsLeft: SplitLine?
    let vsRight: SplitLine?
    
    // New: Home/Away splits
    let home: GameSiteSplits?
    let away: GameSiteSplits?
    
    // New: Day/Night splits
    let dayGame: GameSiteSplits?
    let nightGame: GameSiteSplits?
    
    struct SplitLine: Decodable {
        let avg: String?
        let ops: String?
        let k9: String?
        let bb9: String?
    }
    
    struct GameSiteSplits: Decodable {
        let era: String?
        let whip: String?
        let ip: String?
        let k9: String?
        let bb9: String?
    }

    enum CodingKeys: String, CodingKey {
        case pitcherId
        case season
        case vsLeft = "vsL"
        case vsRight = "vsR"
        case home, away
        case dayGame = "dayGame"
        case nightGame = "nightGame"
    }
}
```

## UI Display Layout

The expanded card will have these sections (in order):

```
[Pitcher Name & Stats Header]
────────────────────────────

[Platoon Splits - 2 columns]
VS LHH              VS RHH
.301 AVG            .231 AVG
4.3 K/9             6.9 K/9
3.2 BB/9            2.3 BB/9
.998 OPS            .663 OPS

────────────────────────────

[Game Site Splits - 2 columns]
HOME                AWAY
6.15 ERA            6.15 ERA
1.43 WHIP           1.43 WHIP
45.1 IP             45.1 IP

────────────────────────────

[Time of Day Splits - 2 columns]
DAY TODAY           NIGHT
4.08 ERA            6.22 ERA
1.23 WHIP           1.51 WHIP
28.2 IP             46.1 IP
```

## Questions for Backend

1. Can you add `home`, `away`, `dayGame`, `nightGame` to the pitcher-splits response?
2. What stats should these contain? (ERA, WHIP, IP required; K/9, BB/9 optional)
3. How should these be calculated? (Season to date, vs opposing lineup, filtered by game time?)
4. Fallback behavior: If no data for a category (e.g., pitcher hasn't played day games), return `null` for that object or empty stats with `"—"`?

## Implementation Notes

- Display only if data exists (hide section if all stats are null)
- Use same styling as platoon splits (stat label on left, value on right)
- Color K/9 in cyan for consistency
- Keep card height reasonable (may need to make card scrollable if too tall)

## Status
⏳ Waiting for backend to add home/away/day/night splits to `/api/pitcher-splits/{pitcherId}`
