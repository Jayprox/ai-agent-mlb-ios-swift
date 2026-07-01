# F5 ML & F5 RL Badge Implementation — Complete

**Status:** ✅ Implemented  
**Date:** June 30, 2026

---

## Overview

Added full support for F5 ML and F5 RL market HIT/MISS badge calculations. F5 markets differ from other game markets in that they require per-inning boxscore data (to sum runs in innings 1-5), not just final game scores.

---

## Changes Made

### 1. BoxscoreModels.swift — Added Per-Inning Data Structures

Added new models to capture the linescore innings array from the boxscore API:

```swift
// Boxscore linescore with per-inning breakdown
struct BoxscoreLinescore: Decodable {
    let innings: [InningScore]
    let away: BoxscoreTeam?
    let home: BoxscoreTeam?
}

// Per-inning score
struct InningScore: Decodable {
    let num: Int
    let away: Int?
    let home: Int?
}

// Team stats in boxscore
struct BoxscoreTeam: Decodable {
    let runs: Int?
    let hits: Int?
    let errors: Int?
}
```

Updated `GameBoxscore` to include `gamePk` and `linescore` fields:

```swift
struct GameBoxscore: Decodable {
    let gamePk: Int
    let isFinal: Bool
    let linescore: BoxscoreLinescore?  // NEW
    let batting: BattingGroup?
    let pitching: PitchingGroup?
}
```

### 2. BoxscoreManager.swift — Cache Innings Data

Added a second cache for storing per-inning data:

```swift
private var inningsCache: [Int: [InningScore]] = [:]  // gamePk → innings array
```

Modified `fetchBoxscore()` to extract and cache the innings array:

```swift
// Cache innings data for F5 calculations
if let inningsArray = boxscore.linescore?.innings, !inningsArray.isEmpty {
    DispatchQueue.main.async {
        self.inningsCache[gamePk] = inningsArray
    }
}
```

Added public method to retrieve cached innings:

```swift
func innings(for gamePk: Int) -> [InningScore]? {
    inningsCache[gamePk]
}
```

Updated `clearCache()` to also clear innings cache.

### 3. BoardViewModel.swift — F5 Outcome Calculation

Added two new methods to calculate F5 market outcomes:

#### F5 ML (First 5 Inning Moneyline)

```swift
private func calculateF5MLOutcome(candidate: BoardCandidate) -> BadgeOutcome {
    guard let gamePk = candidate.gamePk else { return .pending }
    guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { return .pending }
    guard innings.count >= 5 else { return .pending }

    let f5Away = innings[0..<5].reduce(0) { $0 + ($1.away ?? 0) }
    let f5Home = innings[0..<5].reduce(0) { $0 + ($1.home ?? 0) }

    if f5Away == f5Home { return .pending }  // F5 tie = push

    let lean = candidate.lean?.uppercased() ?? "HOME"
    let hit = lean == "HOME" ? f5Home > f5Away : f5Away > f5Home
    return hit ? .hit : .miss
}
```

#### F5 RL (First 5 Inning Run Line / Spread)

```swift
private func calculateF5RLOutcome(candidate: BoardCandidate) -> BadgeOutcome {
    guard let gamePk = candidate.gamePk else { return .pending }
    guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { return .pending }
    guard innings.count >= 5 else { return .pending }
    guard let line = candidate.bookLine else { return .pending }

    let f5Away = Double(innings[0..<5].reduce(0) { $0 + ($1.away ?? 0) })
    let f5Home = Double(innings[0..<5].reduce(0) { $0 + ($1.home ?? 0) })

    let lean = candidate.lean?.uppercased() ?? "HOME"
    let hit = lean == "HOME" ? (f5Home + line) > f5Away : (f5Away + line) > f5Home
    return hit ? .hit : .miss
}
```

#### Updated calculateGameOutcome()

Checks for F5 markets first (before accessing linescore) since they use boxscore data:

```swift
func calculateGameOutcome(for candidate: BoardCandidate) -> BadgeOutcome {
    let marketLower = candidate.market.lowercased()

    // Handle F5 markets first (they need boxscore, not linescore)
    if marketLower == "f5ml" {
        return calculateF5MLOutcome(candidate: candidate)
    }
    if marketLower == "f5spread" || marketLower == "f5rl" {
        return calculateF5RLOutcome(candidate: candidate)
    }

    // ... rest of logic for NRFI, total, ML, spread ...
}
```

### 4. BoardViewModel.swift — Updated hitStats()

Modified to properly count F5 market badges using the new innings cache:

```swift
for candidate in candidates {
    if isGameMarket {
        guard let gamePk = candidate.gamePk else { continue }
        let marketLower = market.rawValue.lowercased()

        // Check if game is final
        let isF5Market = ["f5ml", "f5spread"].contains(marketLower)
        if isF5Market {
            // F5 markets need boxscore innings data
            guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { continue }
            guard innings.count >= 5 else { continue }  // Need at least 5 innings
        } else {
            // Other game markets need linescore and game must be final
            guard let linescore = GameResultManager.shared.linescore(for: gamePk) else { continue }
            guard let inning = linescore.inning, inning >= 9 else { continue }
        }

        graded += 1
        let outcome = calculateGameOutcome(for: candidate)
        if outcome == .hit {
            hits += 1
        }
    }
    // ... rest of logic ...
}
```

---

## How It Works

1. **Boxscore Fetching:** Already fetched in `BoardViewModel.load()` via `BoxscoreManager.shared.fetchBoxscore()` for live/final games
2. **Innings Caching:** The `fetchBoxscore()` method extracts `linescore.innings` array and stores it in `inningsCache` keyed by gamePk
3. **F5 Calculation:** When a card is displayed or badge is calculated:
   - Retrieve cached innings via `BoxscoreManager.shared.innings(for: gamePk)`
   - Sum runs from `innings[0..<5]` for away and home teams
   - Compare against lean and line to determine HIT/MISS
4. **Tab Counters:** `hitStats()` now counts F5 market badges in the Games tab

---

## Badge Display

- **F5 Tie (push):** Returns `.pending` — no badge shown
- **F5 HIT:** Shows "HIT ✓" in green
- **F5 MISS:** Shows "MISS ✗" in red
- **F5 Not Ready:** Shows "PENDING" if innings array hasn't loaded yet

---

## Testing Checklist

- [ ] F5 ML badges appear on final games with 5+ innings completed
- [ ] F5 RL badges appear with correct line application
- [ ] Games tab sub-tab counter badges now include F5 market hits/total
- [ ] F5 tie (push) correctly shows no badge
- [ ] Border color applies (green for HIT, red for MISS, none for PENDING)
- [ ] Test on both iPhone and iPad layouts
- [ ] Test with various game states (live → final transition)

---

## Files Modified

1. `BoxscoreModels.swift` — Added data structures for innings
2. `BoxscoreManager.swift` — Added innings cache and retrieval method
3. `BoardViewModel.swift` — Added F5 outcome calculation and hitStats update

All changes follow the exact logic from the web app implementation documented in `IOS_F5_HIT_MISS.md`.
