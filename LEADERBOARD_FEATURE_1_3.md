# Leaderboard Feature — v1.3 Proposal

## Overview

A public leaderboard displaying ranked users based on **win rate** or **P&L**, sortable by either metric. Users can quickly see how their performance stacks up against the community.

---

## Feature Concept

### Primary View
- **Default sort:** Win Rate (descending)
- **Alt sort:** P&L (descending)
- **Segmented control** to switch between the two
- **Ranked list** showing position, username, primary metric, and pick count

### Win Rate Sort Example
```
1  Player A     68%     85 picks
2  Player B     65%    120 picks
3  Player C     62%     45 picks
4  Player D     60%     95 picks
...
```

### P&L Sort Example
```
1  Player X    +45.2u   180 picks
2  Player Y    +28.5u    95 picks
3  Player Z    +12.0u    50 picks
4  Player W     +8.1u    38 picks
...
```

---

## Data Requirements

### Per-User Aggregates Needed

```json
{
  "userId": "...",
  "username": "Player A",
  "winRate": 0.68,
  "totalPicks": 85,
  "gradedPicks": 85,
  "hits": 58,
  "misses": 27,
  "pnl": 45.2,
  "currency": "u"
}
```

### Metrics Definitions

| Metric | Formula | Notes |
|--------|---------|-------|
| **Win Rate** | `hits / gradedPicks` | Percentage; graded picks only |
| **P&L** | Sum of all pick units won/lost | User-supplied unit value × hit/miss |
| **Total Picks** | Count of all logged picks | Includes pending, graded, PPD, scratch |
| **Graded Picks** | Count where resultHit or gradeStatus set | Excludes pending |

---

## Backend Requirements

### New Endpoint

```
GET /api/leaderboard?sortBy=win_rate|pnl&limit=100&offset=0
```

**Query Parameters:**
- `sortBy` — `"win_rate"` (default) or `"pnl"`
- `limit` — Results per page (default 100, max 500)
- `offset` — Pagination offset (default 0)

**Response:**
```json
{
  "leaderboard": [
    {
      "rank": 1,
      "userId": "...",
      "username": "Player A",
      "winRate": 0.68,
      "pnl": 45.2,
      "totalPicks": 85,
      "gradedPicks": 85
    },
    {
      "rank": 2,
      "userId": "...",
      "username": "Player B",
      "winRate": 0.65,
      "pnl": 28.5,
      "totalPicks": 120,
      "gradedPicks": 120
    }
    // ...
  ],
  "totalUsers": 847,
  "sortedBy": "win_rate"
}
```

### Calculation Logic

The leaderboard should:
1. Query all users with at least **N graded picks** (suggest N=1, or configurable)
2. Calculate per-user aggregates from the `picks` table
3. Sort by selected metric (descending)
4. Return paginated results with rank

**SQL Pseudocode:**
```sql
SELECT
  ROW_NUMBER() OVER (ORDER BY {metric} DESC) as rank,
  user_id,
  username,
  COUNT(CASE WHEN result_hit = true THEN 1 END) * 1.0 / COUNT(*) as win_rate,
  SUM(pnl) as pnl,
  COUNT(*) as total_picks,
  COUNT(CASE WHEN resolved_at IS NOT NULL THEN 1 END) as graded_picks
FROM picks
WHERE resolved_at IS NOT NULL
GROUP BY user_id, username
HAVING COUNT(*) >= {min_picks}
ORDER BY {metric} DESC
LIMIT {limit} OFFSET {offset}
```

---

## Design Questions for Backend

1. **Minimum picks threshold?**
   - Should users with <1 graded pick appear? (Suggest min=1 or min=5)
   - Or should they be excluded from leaderboard entirely?

2. **Tie-breaking strategy?**
   - If two users have same win rate (e.g., 65%), what's the secondary sort?
   - Options: P&L (descending), pick count (descending), or by creation date

3. **Public leaderboard?**
   - Show all users (current assumption)?
   - Or friends-only / opt-in?

4. **Historical snapshots?**
   - Should leaderboard be static (daily snapshot)?
   - Or real-time (updates as picks are graded)?
   - Suggest: Real-time is simpler for v1.3

5. **Performance expectations?**
   - How many active users? (Affects pagination strategy)
   - Can the aggregation query be optimized with indices on `picks(user_id, resolved_at, result_hit)`?

6. **Caching?**
   - Worth caching for 5–15 minutes to reduce database load?
   - Or acceptable to query on demand?

---

## iOS/Web Implementation Plan

Once endpoint is ready:

1. **iOS:** Create `LeaderboardView` + `LeaderboardViewModel`
2. **Web:** Add leaderboard tab to dashboard
3. **Both:** Display leaderboard with sortable tabs + pagination
4. **Both:** Show current user's rank (if exists in leaderboard)

---

## Timeline

- **Backend:** Design + implement endpoint (~2–3 days)
- **iOS:** Implement UI + hook to endpoint (~1–2 days)
- **Web:** Implement matching feature (parallel, ~1–2 days)
- **Testing:** QA + refinement (~1 day)

---

## Future Enhancements (v1.4+)

- Filter by market (HR, Hits, K, etc.)
- Filter by date range (last 7 days, 30 days, all-time)
- User profile cards (click rank to see user's recent picks)
- Friends-only leaderboard toggle
- Seasonal/monthly resets
- Achievements (e.g., "100 picks milestone")

---

## References

- Pick model: `/api/picks` endpoint
- User aggregates: `picks` table, grouped by user_id
- Grading data: `result_hit`, `resolved_at` fields on pick

---

**Requested By:** iOS v1.3 Development  
**Date:** June 30, 2026  
**Priority:** Feature (non-blocking for v1.2)
