# Umpire Data Enhancement — Backend Request

## Current State
The `/api/umpires/:gamePk` endpoint returns basic stats:
```json
{
  "homePlate": {
    "name": "Jansen Visconti",
    "kRate": "23.1%",
    "bbRate": "8.2%",
    "tendency": "Pitcher-favorable",
    "rating": "Pitcher Ump"
  }
}
```

## What we need

### Enhanced UmpireStats response
```json
{
  "gamePk": 747056,
  "homePlate": {
    "id": 12345,
    "name": "Jansen Visconti",
    
    // Current fields
    "kRate": "23.1%",
    "bbRate": "8.2%",
    "tendency": "Pitcher-favorable",
    "rating": "Pitcher Ump",
    
    // NEW: Performance metrics
    "accuracy": "94.4%",          // How often calls match Hawk-Eye
    "vsExp": "+1.37%",            // vs expected (above/below average)
    "consistency": "95.5%",        // How consistent across series
    "favorPerGame": "0.60",        // Pitch favor per game to pitcher/batter
    
    // NEW: Status badges
    "scorecardLive": true,         // Has recent game scorecard available
    "scoreStatus": "ACCURATE",     // "ACCURATE" | "BIASED" | "NEUTRAL"
    
    // NEW: Current game status
    "gameStatus": "Awaiting assignment",  // or "Active", "Completed", etc.
    
    // NEW: Season stats (optional)
    "season": 2026,
    "gamesWorked": 118,
    "totalCalls": 2847
  }
}
```

## Display on iOS
```
┌─────────────────────────────────────┐
│ HOME PLATE UMPIRE                   │
│                                     │
│ Jansen Visconti  ACCURATE           │
│ SCORECARD LIVE                      │
│ Awaiting assignment                 │
│                                     │
│ 94.4%        +1.37%                 │
│ ACCURACY     VS EXP                 │
│                                     │
│ 95.5%        0.60                   │
│ CONSISTENCY  FAVOR/GM               │
│                                     │
│ Pitcher-favorable · 23.1% K rate    │
└─────────────────────────────────────┘
```

## Badge colors
- `ACCURATE` → Green (#22c55e)
- `BIASED` → Red (#ef4444)
- `NEUTRAL` → Amber (#f59e0b)
- `SCORECARD LIVE` → Green

## Notes
- Accuracy comes from Hawk-Eye comparison (if available)
- vsExp is deviation from league average
- Consistency measures call consistency within a series
- favorPerGame shows pitcher/batter lean per game
- Status can be "Awaiting assignment", "Active", "Completed", etc.
