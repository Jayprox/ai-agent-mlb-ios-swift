# Unified Game Detail Endpoint — `GET /api/game/:gamePk`

## Overview

New backend endpoint consolidates 5–8 individual calls into a single request when users tap a game card.

---

## Endpoint

```
GET /api/game/:gamePk
GET /api/game/:gamePk?date=2026-06-25   ← optional, for historical dates
```

---

## Response Shape

```json
{
  "gamePk": 747056,
  "lineups": { ... },
  "umpire": { ... },
  "nrfi": { ... },
  "weather": { ... },
  "bullpen": { ... },
  "homePitcher": {
    "id": 592789,
    "stats": {
      "era": 3.12,
      "whip": 1.08,
      "strikeouts": 87
    },
    "gamelog": [ ... ],
    "arsenal": { ... }
  },
  "awayPitcher": {
    "id": 669923,
    "stats": { ... },
    "gamelog": [ ... ],
    "arsenal": { ... }
  },
  "teamStats": {
    "home": { ... },
    "away": { ... }
  },
  "fetchedAt": "2026-06-25T18:04:22.000Z"
}
```

**All fields are nullable.** If a sub-component fails or isn't available (e.g. lineups not posted), that key returns `null`.

---

## What This Replaces

| Old Call | Now Covered By |
|---|---|
| `GET /api/lineups/:gamePk` | `lineups` |
| `GET /api/umpires/:gamePk` | `umpire` |
| `GET /api/nrfi/:gamePk` | `nrfi` |
| Weather fetch | `weather` |
| `GET /api/bullpen/:gamePk` | `bullpen` |
| `GET /api/players/:id/stats?group=pitching` × 2 | `homePitcher.stats`, `awayPitcher.stats` |
| `GET /api/players/:id/gamelog?group=pitching` × 2 | `homePitcher.gamelog`, `awayPitcher.gamelog` |
| `GET /api/arsenal/:id` × 2 | `homePitcher.arsenal`, `awayPitcher.arsenal` |
| `GET /api/team-stats/:teamId` × 2 | `teamStats.home`, `teamStats.away` |

---

## Key Notes

### Pitcher Stats Format

The `homePitcher.stats` and `awayPitcher.stats` use the same summary shape as `pitcherStatsMap` in the slate bundle:

```json
{
  "era": 3.12,
  "whip": 1.08,
  "k9": 9.4
}
```

Uses `k9` (not `kPer9`) — consistent with slate bundle format. Your `PitcherStats` Swift model maps directly here.

### Rate Limiting & Caching

- Backend runs all sub-fetches with concurrency cap of 4
- In-flight deduplication: same game tapped twice = one set of MLB API calls
- NRFI and weather typically warm from slate bundle load (instant cache hits)

### Error Handling

Uses `Promise.allSettled` internally — partial failures return partial data, not a 5xx error. Treat `null` fields as "not yet available" rather than errors.

---

## Adoption Strategy

### Option 1: Incremental Migration (Recommended)

1. Game detail view: Adopt `GET /api/game/:gamePk`
2. Other screens: Keep individual endpoint calls until ready to migrate
3. No breaking changes — individual endpoints remain available

### Option 2: Full Replacement

Replace all game detail fetches with the unified endpoint. Performance improvement: 5–8 requests → 1 request.

---

## Implementation for iOS

### Current GameDetailViewModel Usage

```swift
// OLD: Multiple calls
let odds = try await APIClient.shared.get(path: "/api/odds/:gamePk")
let lineup = try await APIClient.shared.get(path: "/api/lineups/:gamePk")
let umpire = try await APIClient.shared.get(path: "/api/umpires/:gamePk")
// ... etc

// NEW: Single call
let detail: GameDetail = try await APIClient.shared.get(
    path: "/api/game/\(game.gamePk)"
)
```

### Model Update

```swift
struct GameDetail: Decodable {
    let gamePk: Int
    let lineups: [String: Any]?
    let umpire: UmpireData?
    let nrfi: NRFIData?
    let weather: WeatherData?
    let bullpen: BullpenData?
    let homePitcher: PitcherDetail?
    let awayPitcher: PitcherDetail?
    let teamStats: TeamStatsData?
    let fetchedAt: String?
}

struct PitcherDetail: Decodable {
    let id: Int
    let stats: PitcherStats?
    let gamelog: [GameLogEntry]?
    let arsenal: ArsenalData?
}
```

---

## Status

✅ Endpoint is live and stable  
✅ Individual endpoints remain available for incremental migration  
✅ Ready for iOS adoption

---

## Next Steps

- [ ] Add to GameDetailViewModel for game tap flow
- [ ] Update models as needed
- [ ] Test with game detail view
- [ ] Monitor performance improvement
