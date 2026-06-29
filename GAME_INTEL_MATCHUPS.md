# Game Intel: Top Matchups & Primary Chase Pitch

## Overview
Add two new intel sections to Game Overview tab to provide matchup context:
1. **Top Matchups** — Key batter scores against this pitcher
2. **Primary Chase Pitch** — Pitcher's best pitch against opposing lineup

---

## 1. Top Matchups Section

### Display
Shows top 3-5 batters in the opposing lineup with their matchup scores (0-100):

```
TOP MATCHUPS
Dylan Beavers    50.9
Adley Rutschman  45.2
Samuel Basallo   44.6
```

### Data Requirements

**Endpoint:** Enhance `/api/game/:gamePk` or create `/api/game/:gamePk/matchups`

**Response Structure:**
```json
{
  "gamePk": 123456,
  "matchups": [
    {
      "batter": {
        "id": 407812,
        "name": "Dylan Beavers",
        "position": "RF"
      },
      "pitcher": {
        "id": 641793,
        "name": "Zack Littell"
      },
      "matchupScore": 50.9,    // 0-100 scale
      "trend": "up",           // "up", "down", "neutral" (optional)
      "reason": "Good K rate"  // (optional)
    }
  ]
}
```

### Swift Model
```swift
struct MatchupData: Decodable, Identifiable {
    var id: String { "\(batter.id)-\(pitcher.id)" }
    
    let batter: PlayerInfo
    let pitcher: PlayerInfo
    let matchupScore: Double
    let trend: String?
    let reason: String?
    
    struct PlayerInfo: Decodable {
        let id: Int
        let name: String
        let position: String?
    }
}
```

### Display Logic
- Show top 3-5 matchups by score (sorted descending)
- Color-code scores: green (>=45), amber (30-44), red (<30)
- Show in simple 2-column format: Name | Score

---

## 2. Primary Chase Pitch Section

### Display
Shows pitcher's best pitch against the opposing lineup:

```
PRIMARY CHASE PITCH
Sweeper — 26% whiff · lineup AVG .141 vs it (weak spot)
```

### Data Requirements

**Use existing `/api/arsenal/:pitcherId`** — compute client-side

**Calculation:**
1. For each pitch type in `arsenal[]`
2. Compute a "weakness score" based on:
   - whiffPct (higher = better for pitcher)
   - ba (batting average against, lower = better)
   - usagePct (only consider pitches >= 10% usage)
3. Select pitch with highest weakness score
4. Identify if it's a weakness for the opposing team (low BA against)

**Weakness Score Formula:**
```swift
func pitchWeaknessScore(pitch: PitchInfo) -> Double {
    guard let whiff = pitch.whiffRate, let ba = pitch.avg else { return 0 }
    let baVal = Double(ba.replacingOccurrences(of: ".", with: "")) ?? 0
    let whiffWeight = whiff * 0.6
    let baWeight = (500 - baVal) * 0.4  // Invert: lower BA = higher score
    return whiffWeight + baWeight
}
```

### Display Logic
- Show pitch name and abbreviation
- Display whiffPct (green if >= 28%)
- Show BA against
- Add context: "weak spot" if BA < .200, "average" if .200-.250, "strength" if > .250
- Optional: show velocity comparison to league average

---

## 3. First Inning Tendencies Enhancement

### Current State
Already displaying via NRFI card in GameOverviewView

### Enhancement
Expand to show:
- YRFI % (same format as NRFI)
- Both away and home team tendencies
- First inning scoring rates for each team
- LIVE status indicator

### Data
Already available from `/api/nrfi/:gamePk` endpoint — just need to expand display

**Enhanced Display:**
```
FIRST INNING TENDENCIES
YRFI 54%  LIVE            WSH avg 0.7 R/1st inn  BAL avg 0.5 R/1st inn

WSH 1ST INN          BAL 1ST INN
35%                  30%
scored               scored
```

---

## Implementation Priority

**1. Primary Chase Pitch** — Compute client-side from existing arsenal data (ready now)
**2. First Inning Tendencies expansion** — Enhance NRFI display with YRFI + scoring % (ready now)
**3. Top Matchups** — Requires backend endpoint (new data needed)

---

## Questions for Backend

1. **Top Matchups:** Should matchup scores come from:
   - A new endpoint `/api/game/:gamePk/matchups`?
   - Or enhance existing game endpoint?
   - How are scores computed (proprietary model)?

2. **Data freshness:** Should matchup scores be:
   - Pre-computed for the day?
   - Computed on-demand?
   - Cached with 1hr TTL?

3. **Sample:** Can you provide matchup data for a current game so we can test integration?

---

## Status
✅ Primary Chase Pitch — ready (client-side computation)
✅ First Inning Tendencies expansion — ready (data exists)
⏳ Top Matchups — waiting for backend matchup endpoint
