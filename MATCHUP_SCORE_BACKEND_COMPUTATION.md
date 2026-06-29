# Matchup Score Computation — Backend Responsibility

## Issue
The `matchupScore` returned by `/api/game/{gamePk}/matchups` should be **computed server-side**, not expected to be computed by each client (web, iOS, Android, etc.).

Currently the iOS app is using the backend-provided `matchupScore`, but we need to confirm that:
1. The backend is computing this score consistently
2. All platforms use the same backend value
3. There is no frontend computation fallback

## Current State (iOS)
iOS is consuming `matchupScore` directly from the `/api/game/{gamePk}/matchups` endpoint:

```json
{
  "matchups": [
    {
      "batter": { "id": 407812, "name": "Dylan Beavers" },
      "pitcher": { "id": 641793, "name": "Zack Littell" },
      "matchupScore": 68.4,    // ← Used directly, no client-side computation
      "trend": "up",
      "reason": "Pitcher allows .847 OPS vs RHH"
    }
  ]
}
```

## Requirement
**Confirm that the backend is computing `matchupScore` server-side** using a consistent algorithm across all platforms (web, iOS, Android, APIs, etc.).

The calculation should account for:
- Pitcher arsenal (pitch types and usage %)
- Batter splits by pitch type (AVG, whiff rate, SLG)
- Handedness matchup penalty (same-hand pitcher/batter)
- Normalization to 0–100 scale

## Questions for Backend Team

1. **Is `matchupScore` computed server-side?** Or is the backend returning raw data and expecting clients to compute it?

2. **If server-side:** What's the algorithm? (We need consistency across platforms.)

3. **If client-side:** Which platforms are doing the computation? (Web, iOS, Android?)
   - If multiple platforms compute it differently, scores will be inconsistent.
   - We should consolidate to backend computation.

4. **Data freshness:** Is the score updated in real-time, or cached? If cached, what's the TTL?

## Recommendation
Consolidate all matchup score computation to the backend:

**Pros:**
- Single source of truth
- All platforms (web, iOS, Android, APIs) show identical scores
- Easy to update algorithm globally without shipping app updates
- Easier to optimize (cache scores, parallelize computation)

**Cons:**
- Backend needs to compute scores for all games/batters (more CPU)
- Add computation to game load time (if not pre-computed/cached)

## Status
Awaiting backend confirmation on computation ownership.
