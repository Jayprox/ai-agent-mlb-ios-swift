# Pitcher Advanced Stats & Arsenal Visualization

## Overview
Enhance the Game Overview pitcher card with advanced statistics and pitch arsenal breakdown, matching the web app display:
1. **Advanced Stats Line** — SwStr%, Chase, F-Str%, Barrels, HRs, xwOBA, FBv
2. **Visual Split Charts** — Bar charts showing VS LHH / VS RHH effectiveness
3. **Pitch Breakdown Table** — Pitch type performance (2ER, 1ER, SER, 4ER, etc.)

---

## 1. Advanced Pitcher Stats

### Data Structure
```json
{
  "pitcherId": 641793,
  "advancedStats": {
    "swStr": "7%",           // Swinging strike %
    "chase": "28.4%",        // Chase %
    "fStr": "50.8%",         // First strike %
    "barrels": "11.3%",      // Barrel %
    "hrs": "46.7%",          // HR %
    "xwOBA": "0.387",        // Expected wOBA
    "fbv": "94.4"            // Fastball velocity (mph)
  }
}
```

### Swift Model
```swift
struct PitcherAdvancedStats: Decodable {
    let swStr: String?       // Swinging strike %
    let chase: String?       // Chase %
    let fStr: String?        // First strike %
    let barrels: String?     // Barrel %
    let hrs: String?         // HR %
    let xwOBA: String?       // Expected wOBA
    let fbv: String?         // Fastball velocity
}
```

### Display
Show as a single-line stat row at top of pitcher card:
```
SwStr%: 7% | Chase: 28.4% | F-Str%: 50.8% | Barrels: 11.3% | HRs: 46.7% | xwOBA: 0.387 | FBv: 94.4
```

---

## 2. Split Effectiveness Bars

### Data Structure
Enhance existing platoon splits with bar chart data:

```json
{
  "vsLeft": {
    "avg": ".301",
    "ops": ".998",
    "k9": "4.3",
    "bb9": "3.2",
    
    "barChart": {
      "green": 60,     // % positive outcomes
      "yellow": 20,    // % neutral
      "red": 20        // % negative outcomes
    }
  },
  "vsRight": {
    ...same structure...
  }
}
```

### Swift Model Update
```swift
struct SplitLine: Decodable {
    let avg: String?
    let ops: String?
    let k9: String?
    let bb9: String?
    
    let barChart: BarChartData?
    
    struct BarChartData: Decodable {
        let green: Int?    // % positive (0-100)
        let yellow: Int?   // % neutral (0-100)
        let red: Int?      // % negative (0-100)
    }
}
```

### Display
Show horizontal stacked bar chart below split stats:
```
[====== GREEN ====== YELLOW RED]
```

---

## 3. Pitch Breakdown Table

### Data Structure
Pitch type performance metrics:

```json
{
  "pitcherId": 641793,
  "pitchBreakdown": [
    {
      "pitch": "4-Seam",
      "shortCode": "FF",
      "count": 452,        // Pitch count
      "k": 78,             // Strikeouts
      "rc": 2,             // Runs created
      "era": 4.0,          // ERA against
      "result": "L"        // W/L/Tie indicator
    },
    {
      "pitch": "Slider",
      "shortCode": "SL",
      "count": 289,
      "k": 45,
      "rc": 3,
      "era": 3.2,
      "result": "W"
    },
    {
      "pitch": "Changeup",
      "shortCode": "CH",
      "count": 156,
      "k": 28,
      "rc": 1,
      "era": 2.8,
      "result": "W"
    },
    {
      "pitch": "Curveball",
      "shortCode": "CU",
      "count": 98,
      "k": 24,
      "rc": 0,
      "era": 1.5,
      "result": "W"
    }
  ]
}
```

### Swift Model
```swift
struct PitchBreakdown: Decodable, Identifiable {
    var id: String { pitch }
    
    let pitch: String         // Full name: "4-Seam", "Slider", etc.
    let shortCode: String     // "FF", "SL", "CH", "CU"
    let count: Int?           // Total pitches thrown
    let k: Int?               // Strikeouts
    let rc: Int?              // Runs created
    let era: String?          // ERA against
    let result: String?       // "W", "L", "T"
}
```

### Display
Show as a table below splits:
```
PITCH         COUNT  K   RC  ERA  RESULT
4-Seam (FF)   452    78  2   4.0  L
Slider (SL)   289    45  3   3.2  W
Changeup (CH) 156    28  1   2.8  W
Curveball (CU) 98    24  0   1.5  W
```

---

## UI Layout

Final pitcher card structure:
```
[Pitcher Header: Name, Team, vs Opponent]
────────────────────────────────────────

[Main Stats: ERA, WHIP, K/9, BB/9, etc.]

[Advanced Stats Line]
SwStr%: 7% | Chase: 28.4% | ...

────────────────────────────────────────

[Platoon Splits with Bars]
VS LHH              VS RHH
.301 AVG            .231 AVG
[======= BAR =======] [RED BAR=]

────────────────────────────────────────

[Pitch Breakdown Table]
PITCH         COUNT  K   ERA  RESULT
FF            452    78  4.0  L
SL            289    45  3.2  W
...
```

---

## Backend Questions

1. **Advanced stats endpoint:** Should these be added to pitcher-splits, or do they come from arsenal/a separate endpoint?

2. **Bar chart percentages:** How should green/yellow/red be calculated? (e.g., based on wOBA, expected runs, hit type?)

3. **Pitch breakdown:** Should this come from arsenal data, or is there a specific pitch-detail endpoint?

4. **Sample size filtering:** Should we show pitches with < X throws (e.g., < 50 total)? Or show all?

5. **Pitch names:** What's the canonical list of pitch types and short codes (FF, SL, CH, CU, SI, KC, etc.)?

---

## Status
⏳ Waiting for backend to provide advanced stats, bar chart data, and pitch breakdown

## Implementation Priority
1. Advanced stats line (simplest, high value)
2. Pitch breakdown table (moderate complexity, very useful)
3. Visual bar charts (design-heavy, nice-to-have)
