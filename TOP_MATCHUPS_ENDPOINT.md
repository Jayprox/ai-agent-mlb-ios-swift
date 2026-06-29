# Top Matchups Endpoint Specification

## Overview
The **Top Matchups** section displays key batter-vs-pitcher matchup scores on the Game Overview tab. This helps users quickly identify which opposing batters have the best/worst records against the starting pitcher.

---

## Endpoint

**Path:** `GET /api/game/:gamePk/matchups`

**Parameters:**
- `gamePk` (path): Game ID from MLB Stats API

**Response:** Array of matchup objects, sorted by matchupScore (descending)

---

## Response Structure

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
      "matchupScore": 50.9,
      "trend": "up",
      "reason": "Good K rate vs RHP"
    },
    {
      "batter": {
        "id": 543558,
        "name": "Adley Rutschman",
        "position": "C"
      },
      "pitcher": {
        "id": 641793,
        "name": "Zack Littell"
      },
      "matchupScore": 45.2,
      "trend": "neutral",
      "reason": null
    },
    {
      "batter": {
        "id": 592195,
        "name": "Samuel Basallo",
        "position": "3B"
      },
      "pitcher": {
        "id": 641793,
        "name": "Zack Littell"
      },
      "matchupScore": 44.6,
      "trend": "down",
      "reason": null
    }
  ]
}
```

---

## Field Details

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `gamePk` | Int | Yes | Game ID for reference |
| `matchups` | Array | Yes | List of matchups, top 3-5 by score |
| `batter.id` | Int | Yes | MLB Stats API player ID |
| `batter.name` | String | Yes | Full batter name |
| `batter.position` | String | No | Defensive position (e.g., "RF", "C") |
| `pitcher.id` | Int | Yes | MLB Stats API pitcher ID |
| `pitcher.name` | String | Yes | Full pitcher name |
| `matchupScore` | Double | Yes | Score 0-100 scale; higher = more favorable for batter |
| `trend` | Enum | No | One of: "up", "down", "neutral"; indicates recent momentum |
| `reason` | String | No | Optional human-readable note explaining the score |

---

## Score Interpretation

The `matchupScore` (0-100) represents how favorable the matchup is for the batter:

- **70-100:** Strong matchup for batter (favorable)
- **50-69:** Average/mixed matchup
- **0-49:** Weak matchup for batter (favorable for pitcher)

The iOS app will color-code these:
- **Green (score >= 45):** Strong matchup
- **Amber (score 30-44):** Average matchup
- **Red (score < 30):** Weak matchup

---

## Computation Notes

Suggested factors in matchup score calculation (not exhaustive):

1. **Historical performance:** H, 2B, HR, K vs pitcher or pitcher type
2. **Splits:** LHH/RHH splits, ballpark factors
3. **Recent form:** Last 30 days vs last season
4. **Velocity/movement adjustments:** If pitcher velo is up/down YoY
5. **Lineup position:** Higher seed/hot batter bonus

The exact formula is proprietary—just ensure scores are on 0-100 scale and sorted descending.

---

## Implementation Priority

This is a **blocking dependency** for the Top Matchups feature. iOS will call this endpoint when loading a game detail and display the results on the Game Overview tab.

**Timeline:** Please provide this endpoint so iOS can integrate before v1.1 App Store submission.

---

## Sample Implementation Checklist

- [ ] Route created: `GET /api/game/:gamePk/matchups`
- [ ] Response includes batter, pitcher, matchupScore, trend, reason
- [ ] Results sorted by matchupScore (highest first)
- [ ] Returns top 3-5 matchups (configurable)
- [ ] Tested with sample game IDs
- [ ] Deployed to staging for iOS testing

---

## Questions

1. **Score computation:** Is this based on career stats, recent form, or a proprietary model? Any constraints on how it's calculated?
2. **Data freshness:** Should these be pre-computed daily, or computed on-demand? Any caching needed?
3. **Fallback:** If a batter has no historical data against this pitcher, what score should we return? (e.g., 50 for "neutral"?)
4. **All batters or starters only?** Should we include pinch-hitters/bench players, or just the starting lineup?

