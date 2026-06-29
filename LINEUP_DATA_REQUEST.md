# Lineup Endpoint Data Request

## Issue
The iOS app's Lineup tab is unable to display batter statistics (position, handedness, batting average) because the `/api/lineups/{gamePk}` endpoint returns those fields as `nil`.

## Current Response
```
Endpoint: GET /api/lineups/{gamePk}

Response shape (actual):
{
  "gamePk": 747056,
  "confirmed": true,
  "away": [
    {
      "id": 123456,
      "name": "James Wood",
      "order": 1,
      "position": null,        // ← nil (needed)
      "batSide": null,         // ← nil (needed)
      "avg": null              // ← nil (needed)
    },
    ...
  ],
  "home": [...]
}
```

## What We Need
The iOS Lineup tab displays batter cards with the following info:

```
1  James Wood
   .257
   ••••
```

For this to work, we need:

| Field | Type | Example | Notes |
|-------|------|---------|-------|
| `position` | String | "OF", "C", "SS" | Defensive position |
| `batSide` | String | "L" or "R" | Batting handedness (L=Left, R=Right) |
| `avg` | String | ".257" | Season batting average |

## Required Changes

**Option 1 (Preferred):** Add these fields to the existing `/api/lineups/{gamePk}` response
- No new endpoint needed
- Minimal backend changes
- All batter data in one response

**Option 2:** Create a new endpoint for detailed lineup stats
- e.g., `GET /api/lineups/{gamePk}/detailed`
- If the existing endpoint can't be modified

## Data Source
These fields should come from the MLB Stats API or your player database:
- `position`: Player's current defensive position
- `batSide`: Player's batting handedness
- `avg`: Season batting average (can be current season or last season)

## Timeline
This is needed for v1.1 App Store submission. Please confirm:
1. Can these fields be added to the existing endpoint?
2. If yes, when will it be deployed?
3. If no, what's the recommended approach?

## Implementation Notes
The iOS model already expects these fields:

```swift
struct LineupBatter: Decodable {
    let position: String?
    let batSide: String?
    let avg: String?
}
```

No iOS changes needed once the backend returns the data.
