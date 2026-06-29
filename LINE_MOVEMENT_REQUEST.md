# Line Movement Data — Backend Request

## Overview
The Intel tab "ODDS & LINE MOVEMENT" card needs detailed sportsbook odds data showing how lines have moved throughout the day, with multi-sportsbook tracking (DK, FD, CZR, MGM, etc.).

## Current State
The `/api/lineups/:gamePk` endpoint returns basic OddsData:
- `awayML`, `homeML` (moneyline)
- `total`, `overOdds`, `underOdds`
- `awaySpread`, `homeSpread`, `awaySpreadOdds`, `homeSpreadOdds`
- `book` (single sportsbook)

## What we need

### Endpoint
```
GET /api/odds/:gamePk/movement
```

### Response shape
```json
{
  "gamePk": 747056,
  "books": [
    {
      "sportsbook": "DK",
      "moneyline": {
        "away": "-168",
        "home": "+164"
      },
      "spread": {
        "away": "-1.5",
        "home": "+1.5",
        "awayOdds": "-115",
        "homeOdds": "-115"
      },
      "total": {
        "line": "9.5",
        "overOdds": "-110",
        "underOdds": "-110"
      }
    },
    {
      "sportsbook": "FD",
      "moneyline": { "away": "-164", "home": "+168" },
      "spread": { ... },
      "total": { ... }
    }
  ],
  "movement": {
    "totalOpened": "10.5",
    "totalCurrent": "9.5",
    "direction": "down",
    "movement": "-1.0"
  },
  "lastUpdated": "2026-06-29T18:35:08.534Z"
}
```

## Display on iOS
```
┌─────────────────────────────────────┐
│ ODDS & LINE MOVEMENT                │
├─────────────────────────────────────┤
│     ML          SPREAD      TOTAL   │
│ DK  -168 +164   -1.5 +1.5   9.5    │
│ FD  -164 +168   -1.5 +1.5   9.5    │
│ CZR -170 +166   -1.5 +1.5   9.5    │
│ MGM -165 +167   -1.5 +1.5   9.5    │
├─────────────────────────────────────┤
│ Movement: Total opened 10.5,        │
│ moved down 1.0 to 9.5               │
└─────────────────────────────────────┘
```

## Sportsbook abbreviations
- `DK` = DraftKings
- `FD` = FanDuel
- `CZR` = Caesars
- `MGM` = MGM
- `BET` = BetMGM (if separate)

## Notes
- Return top 4-5 major sportsbooks
- Update frequency: real-time or hourly cache
- Movement calculation: compare opening line to current line
- Direction: "up", "down", or "flat"
