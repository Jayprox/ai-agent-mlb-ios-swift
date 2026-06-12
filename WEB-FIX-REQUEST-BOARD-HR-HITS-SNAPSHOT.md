# Web/Backend Fix Request — Board HR/Hits empty in `/api/board/snapshot`

> **From:** iOS team (`ai-agent-mlb-ios-swift`)  
> **To:** Web + backend team (`ai-agent-mlb`)  
> **Date:** June 2026  
> **Status:** Blocking iOS Board HR/Hits parity

---

## Problem

The iOS app shows **empty HR and Hits tabs** on Board while the web app shows populated player cards for the same slate date.

iOS reads:

```
GET /api/board/snapshot?date=YYYY-MM-DD
GET /api/board/snapshot?date=YYYY-MM-DD&refresh=1   (manual refresh / forced recompute)
```

Diagnostics on iOS confirm the raw JSON often has:

```json
"hr": [],
"hits": []
```

This is **not** an iOS decode bug — K, Outs, and Games markets from the same snapshot response populate correctly.

---

## Why web works but iOS doesn't

### Web has a client-side fallback iOS does not have

On web (`prop-scout-v7.jsx`), Board always runs `computeBatterBoard("hr"|"hits", ...)` in the browser at render time, then selects data via `sharedMarketOrLive()`:

- Non-empty snapshot market → use snapshot
- Empty snapshot (`[]`) but live compute has candidates → **use live compute**
- Otherwise → `[]`

So when `/api/board/snapshot` returns `"hr": []` / `"hits": []`, **web still shows cards** from browser-side `computeBatterBoard`.

iOS has no local `computeBatterBoard` — it relies on the snapshot API only. For iOS parity **without porting scoring to Swift**, the server must populate `hr` and `hits` correctly in `/api/board/snapshot`.

### Server-side snapshot jobs have a hitting-log parsing bug

Both the scheduled snapshot writer (`dailyAiSnapshot.js`) and on-demand fill (`boardDailySnapshot.js` → `fillMissingMarkets` → `liveBoardData.js`) use the same server path: `gatherLiveBoardData()` + `computeMarketCandidates()`.

**Bug location:** `backend/services/liveBoardData.js` (~L215–221)

**Current (wrong):**

```javascript
const batchData = await internalPost("/api/players/gamelogs/batch", {
  playerIds,
  group: "hitting",
});
if (batchData && typeof batchData === "object") {
  Object.assign(liveHittingLog, batchData);  // BUG
}
```

**API actually returns** (`backend/routes/players.js` ~L298):

```json
{
  "results": {
    "682928": { "avg": ".285", "slg": ".512", "hr": 12, "ops": ".891", "hitRate": [1,0,1,1,0] }
  },
  "misses": []
}
```

**Web client (correct)** — `prop-scout-v7.jsx` ~L3742:

```javascript
setLiveHittingLog(prev => ({ ...prev, ...data.results }));
```

**Server (wrong):** assigns `{ results, misses }` as top-level keys on `liveHittingLog`, so **`liveHittingLog[playerId]` is always undefined**.

**Impact inside `computeBatterBoard`** (`src/board/index.js`):

- Requires `liveHittingLog[playerId]` for each batter
- `hrBoardScore` / `hitBoardScore` return `null` without a gamelog → batter dropped
- Result: **zero HR/Hits candidates** → snapshot persists `"hr": []`, `"hits": []`

K/Outs/Games are unaffected because they use per-pitcher API calls, not the hitting batch path.

---

## Required fix

**File:** `backend/services/liveBoardData.js`

**Change:**

```javascript
// Before
Object.assign(liveHittingLog, batchData);

// After
Object.assign(liveHittingLog, batchData.results ?? {});
```

That is the **minimum required change**. No new endpoint is required for iOS parity.

---

## After deploy — backfill today's snapshot

Once the fix is deployed to Railway, run a forced recompute for today's Honolulu date so Postgres gets non-empty `hr`/`hits` (empty arrays are persisted today):

```bash
DATE=$(TZ=Pacific/Honolulu date +%Y-%m-%d)
API=https://ai-agent-mlb-production.up.railway.app

curl -s "$API/api/board/snapshot?date=$DATE&refresh=1" \
  | jq '{date, generatedAt, hr: (.hr|length), hits: (.hits|length), k: (.k|length), sampleHr: .hr[0].name, sampleHits: .hits[0].name}'
```

Check response header:

| `X-Cache` | Meaning |
|-----------|---------|
| `FALLBACK` | On-demand compute ran this request |
| `MISS` | DB read + possible fill |
| `HIT` | In-memory cache (may be stale; use `refresh=1` for verification) |

**Success criteria:** When lineups exist (confirmed or roster fallback), `hr` and `hits` array lengths should be **> 0**, and sample objects should have `id`, `name`, `score`, `gamePk`, `gameLabel`, etc.

---

## Verification checklist (please confirm when done)

- [ ] `liveBoardData.js` uses `batchData.results ?? {}` (not `batchData` directly)
- [ ] Deployed to production (`ai-agent-mlb-production.up.railway.app`)
- [ ] `curl .../api/board/snapshot?date=TODAY&refresh=1` returns `hr.length > 0` and/or `hits.length > 0` when today's slate has posted lineups
- [ ] Subsequent plain `GET .../api/board/snapshot?date=TODAY` (no refresh) also returns populated `hr`/`hits` from DB
- [ ] Reply to iOS team with: deploy timestamp + curl output snippet showing non-zero counts

---

## What iOS will do after your fix

No Swift scoring port needed. iOS will:

1. Keep `/api/board/snapshot` as the primary Board data source
2. Call `&refresh=1` when HR/Hits (or any empty market) need forced server recompute
3. Poll every ~90s while any snapshot market is still `[]` (matching web)

iOS is waiting on **this backend fix** before HR/Hits can populate via snapshot-only flow.

---

## Related files (web repo)

| File | Role |
|------|------|
| `backend/services/liveBoardData.js` | **Fix here** — `gatherLiveBoardData`, batch gamelog merge |
| `backend/routes/players.js` | `POST /api/players/gamelogs/batch` → `{ results, misses }` |
| `backend/routes/boardDailySnapshot.js` | `GET /api/board/snapshot`, `fillMissingMarkets`, `refresh=1` |
| `backend/jobs/dailyAiSnapshot.js` | Cron snapshot writer (10 AM HI + pregame) |
| `backend/services/boardSnapshotDb.js` | Persists snapshot to Postgres |
| `src/board/index.js` | `computeBatterBoard` — same module used server-side |
| `prop-scout-v7.jsx` | Web live fallback via `sharedMarketOrLive` (reference only) |

---

## Reference docs (already in web repo)

If more context is needed:

- `IOS-BOARD-HR-HITS-HANDOFF.md`
- `IOS-BOARD-HR-HITS-DATA-FLOW.md`

---

## Message back to iOS when complete

Please reply with something like:

> Board HR/Hits snapshot fix deployed at [time].  
> `liveBoardData.js` now uses `batchData.results`.  
> Verified: `curl .../api/board/snapshot?date=YYYY-MM-DD&refresh=1` → hr=N, hits=M (N,M > 0).

iOS will then wire up / verify polling behavior and test on device.
