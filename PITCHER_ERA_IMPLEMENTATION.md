# Pitcher ERA on Slate Cards — Implementation Guide

## Overview
Mobile app needs pitcher ERA displayed on Slate game cards. Web app team has provided implementation guidance for the backend.

## Current State

**Web App Approach:**
- Fetches pitcher stats separately via `/api/players/{pitcherId}/stats?group=pitching`
- Makes 1 call per pitcher (20-30 requests on a 15-game slate)
- Includes: `{ era, whip, kPer9, bbPer9, wins, losses, ip, k, bb }`

**Slate Bundle Response (Current):**
```json
{
  "schedule": [...],
  "oddsMap": {...},
  "nrfiMap": {...},
  "weatherMap": {...},
  "fetchedAt": "..."
}
```

Pitcher info in `schedule.probablePitchers`:
```json
{
  "id": 123456,
  "name": "Seth Lugo",
  "hand": "R",
  "isIL": false
}
```

## Recommended Backend Implementation

**Problem:** Making N×2 individual pitcher stat calls is inefficient (20-30 requests).

**Solution:** Batch-fetch pitcher stats server-side and include in SlateBundle as `pitcherStatsMap`.

### Backend Changes — `backend/routes/slateBundle.js`

Add pitcher stats fetching and caching:

```javascript
const pitcherStatsMap = {};
const pitcherFetches = [];

for (const game of schedule) {
  for (const side of ["home", "away"]) {
    const pitcher = game.probablePitchers?.[side];
    if (!pitcher?.id) continue;

    const cacheKey = `pitcher-stats:${pitcher.id}`;
    const cached = cache.get(cacheKey);
    
    if (cached) {
      pitcherStatsMap[pitcher.id] = cached;
    } else {
      pitcherFetches.push(
        fetchPitcherStats(pitcher.id)
          .then(stats => {
            cache.set(cacheKey, stats, 6 * 60 * 60 * 1000); // 6 hour cache
            pitcherStatsMap[pitcher.id] = stats;
          })
          .catch(() => {}) // graceful failure
      );
    }
  }
}

await Promise.allSettled(pitcherFetches);

// Include in bundle response
const bundle = {
  schedule,
  oddsMap,
  nrfiMap,
  weatherMap,
  pitcherStatsMap,  // ← NEW
  fetchedAt: new Date().toISOString(),
};

response.json(bundle);
```

### Stats Shape per Pitcher

```json
{
  "pitcherStatsMap": {
    "123456": {
      "era": "3.12",
      "whip": "1.08",
      "k9": "9.4",
      "avgIP": "5.2"
    },
    "789012": {
      "era": "4.01",
      "whip": "1.24",
      "k9": "7.8",
      "avgIP": "5.0"
    }
  }
}
```

## Mobile Implementation Plan

Once backend adds `pitcherStatsMap`:

### 1. Update SlateBundle Model

```swift
struct SlateBundle: Decodable {
    let schedule: [SlateGame]
    let oddsMap: [String: OddsData?]?
    let nrfiMap: [String: NRFIData?]?
    let weatherMap: [String: WeatherData?]?
    let kHintsMap: [String: String?]?
    let pitcherStatsMap: [String: PitcherStats]?  // ← NEW
    let fetchedAt: String?
}

struct PitcherStats: Decodable {
    let era: String?
    let whip: String?
    let k9: String?
    let avgIP: String?
}
```

### 2. Update SlateCardView

Display ERA next to pitcher names:

```swift
if let pp = game.probablePitchers {
    HStack(spacing: 4) {
        if let away = pp.away {
            Text(away.name)
            if let stats = vm.pitcherStats(for: away.id), let era = stats.era {
                Text(era)
                    .foregroundColor(.brandTextDim)
            }
        }
        
        Text("vs")
        
        if let home = pp.home {
            Text(home.name)
            if let stats = vm.pitcherStats(for: home.id), let era = stats.era {
                Text(era)
                    .foregroundColor(.brandTextDim)
            }
        }
    }
}
```

### 3. Update SlateViewModel

```swift
@Published var pitcherStatsMap: [String: PitcherStats] = [:]

func load() async {
    let bundle: SlateBundle = try await APIClient.shared.get(...)
    self.pitcherStatsMap = bundle.pitcherStatsMap ?? [:]
}

func pitcherStats(for pitcherId: Int?) -> PitcherStats? {
    guard let id = pitcherId else { return nil }
    return pitcherStatsMap[String(id)]
}
```

## Performance Notes

- **Caching:** 6-hour server-side cache for pitcher stats
- **First cold build:** Small latency hit as pitcher stats are fetched
- **Steady state:** Essentially zero latency — stats served from cache
- **Slate bundle cache:** 5 minutes, so pitcher stat fetches only apply during cold builds

## Timeline

- Backend: Implement `pitcherStatsMap` in SlateBundle
- Mobile: Update models and display once backend is ready

---

**Questions?** Contact the backend team with this guide or refer to the web app implementation in `slateBundle.js`.
