# Cowork / Codex Review Handoff — Board HR/Hits Fix (June 2026)

> **Audience:** Cowork, Codex, and any agent picking up `ai-agent-mlb-ios-swift`  
> **Status:** ✅ Fixed and verified on device (Board → HR and Hits populate)  
> **Last updated:** 2026-06-11

---

## Executive summary

Board **HR** and **Hits** tabs were empty on iOS while the web app showed players for the same slate. Two independent bugs stacked:

1. **Backend (`ai-agent-mlb`)** — server-side snapshot jobs could not build batter candidates because hitting gamelogs were parsed incorrectly.
2. **iOS (`ai-agent-mlb-ios-swift`)** — API returned 35 HR/Hits candidates but Swift decoded **0** because the `hr` stat field is a JSON **number** and the model expected a **String**.

Both are fixed. iOS Board HR/Hits now matches web for scores, AVG/OPS, and player lists.

---

## Project layout (iOS repo)

| Path | Role |
|------|------|
| `Prop Scout MLB/Prop Scout MLB/` | Swift source root |
| `Prop Scout MLB/Prop Scout MLB/ViewModels/BoardViewModel.swift` | Board snapshot fetch + polling |
| `Prop Scout MLB/Prop Scout MLB/Models/BoardModels.swift` | `BoardSnapshot`, `BoardCandidate`, decoders |
| `Prop Scout MLB/Prop Scout MLB/Views/Board/BoardView.swift` | Board UI (tabs, empty state, pull-to-refresh) |
| `Prop Scout MLB/Prop Scout MLB/Models/WhyFactorsBuilder.swift` | Why? modal factor breakdown |
| `Prop Scout MLB/Prop Scout MLB/Network/Endpoints.swift` | API base URL + paths |
| `CODEX-HANDOFF.md` | Earlier Codex tasks (Pick grading, AI Board log pick, shimmer) |
| `iOS-HANDOFF.md` | Original iOS MVP spec |
| `WEB-FIX-REQUEST-BOARD-HR-HITS-SNAPSHOT.md` | Request sent to web/backend team |

**Backend lives in separate repo:** `ai-agent-mlb` (Railway production API).

---

## Symptom

- iOS Board → **HR** / **Hits**: empty or “Lineups not yet posted”
- Web Board → same date: populated player cards
- iOS **K**, **Outs**, **Games** tabs: worked fine (same snapshot endpoint)

---

## Why web worked but iOS didn’t (architecture)

The web app (`prop-scout-v7.jsx`) uses a **two-layer** strategy:

1. `GET /api/board/snapshot?date=…` — shared daily snapshot
2. **Client-side** `computeBatterBoard("hr"|"hits", …)` at render time — live fallback when snapshot markets are `[]`

Selection rule (`sharedMarketOrLive`):

- Non-empty snapshot → use snapshot  
- Empty snapshot but live compute has data → use live compute  
- Else → `[]`

**iOS has no local `computeBatterBoard`.** It must rely on `/api/board/snapshot` returning populated `hr` / `hits` arrays. Polling + `&refresh=1` is iOS’s equivalent of forcing server-side recompute (not browser-side compute).

Full web data-flow writeup (from web repo):

- `ai-agent-mlb/IOS-BOARD-HR-HITS-HANDOFF.md`
- `ai-agent-mlb/IOS-BOARD-HR-HITS-DATA-FLOW.md`

---

## Root cause #1 — Backend batch parsing bug

**File (web repo):** `backend/services/liveBoardData.js` (~L215–221)

**Bug:** After `POST /api/players/gamelogs/batch`, the server merged the whole response object instead of `results`:

```javascript
// Before (wrong)
Object.assign(liveHittingLog, batchData);

// After (fixed)
Object.assign(liveHittingLog, batchData.results ?? {});
```

**Why it mattered:** API returns `{ results: { [playerId]: hlog }, misses: [] }`. Without `.results`, `liveHittingLog[playerId]` was always undefined → `computeBatterBoard` dropped every batter → snapshot persisted `"hr": []`, `"hits": []`.

**Web client was already correct:** `prop-scout-v7.jsx` uses `data.results`.

**Deploy + backfill:**

```bash
DATE=$(TZ=Pacific/Honolulu date +%Y-%m-%d)
curl -s "https://ai-agent-mlb-production.up.railway.app/api/board/snapshot?date=$DATE&refresh=1" \
  | jq '{hr: (.hr|length), hits: (.hits|length), sampleHr: .hr[0].name}'
```

Expect `hr` / `hits` counts **> 0** when lineups exist. Response header `X-Cache: FALLBACK` = on-demand compute ran.

---

## Root cause #2 — iOS decode type mismatch on `hr` field

After the backend fix, DEBUG logs showed:

```
📦 board/snapshot[hr] raw count = 35, decoded count = 0
❌ first element decode error: Expected to decode String but found number instead. Path: hr.
```

**Cause:** `computeBatterBoard` emits season HR as a JSON **integer** (e.g. `"hr": 15`). `BoardCandidate` mapped key `"hr"` to `hrTotal: String?`.

**Effect:** `LossyArray<BoardCandidate>` silently skipped every HR/Hits candidate (by design — protects K/Outs from one bad row). UI showed empty despite 35 items in raw JSON.

---

## iOS changes made (this session)

### 1. `BoardModels.swift`

- Added **`FlexibleString`** enum — decodes `String`, `Int`, or `Double` (same pattern as existing **`FlexibleValue`** for game-market `line` fields).
- Changed `BoardCandidate.hrTotal` from `String?` to **`FlexibleString?`** (JSON key still `"hr"`).
- Use `hrTotal?.stringValue` anywhere a display string or `Int()` parse is needed.

### 2. `WhyFactorsBuilder.swift`

- Updated HR pace factor: `c.hrTotal?.stringValue` instead of `c.hrTotal` directly.

### 3. `BoardViewModel.swift`

Aligned with web Board polling behavior:

| Behavior | Before | After |
|----------|--------|-------|
| Poll interval | 75s | **90s** (matches web) |
| Poll while any market is `[]` | plain `GET` | **`GET …&refresh=1`** |
| After initial load if empty markets | poll only | **immediate `refresh=1`**, then poll with refresh |

Flow in `loadAndPollIfNeeded()`:

1. `load()` — plain snapshot GET  
2. If `shouldKeepPolling` → `load(refresh: true)`  
3. Loop every 90s with `load(refresh: true)` until all markets populated or view dismissed  

Manual refresh (pull-to-refresh, “Check now” button) already used `refresh=1`.

### 4. Documentation / coordination

- **`WEB-FIX-REQUEST-BOARD-HR-HITS-SNAPSHOT.md`** — handoff sent to web/backend chat describing the `liveBoardData.js` fix.

---

## Verification (completed)

1. **Production API** — `hr` / `hits` arrays non-empty after backend deploy + `refresh=1`.
2. **iOS DEBUG diagnostic** — `raw count` == `decoded count` (e.g. 35 == 35).
3. **Device** — Board → Hits shows same top players/scores as web (e.g. Alec Burleson 82, Josh Jung 81, Freddie Freeman 80).

---

## DEBUG tooling (keep for future Board issues)

In **`BoardViewModel`**, `#if DEBUG` block `diagnoseHitsAndHR` runs on manual refresh. It:

- Re-fetches raw JSON  
- Compares raw vs decoded counts for `hr` / `hits`  
- Prints first-element keys + decode error if mismatch  

**How to read it:**

| Log | Meaning |
|-----|---------|
| `raw count = 0` | Backend returned empty — server/data issue |
| `raw count = 35, decoded count = 0` | Swift model mismatch — fix `BoardCandidate` decoding |
| `raw count = 35, decoded count = 35` | ✅ Working |

---

## Board API contract (iOS expectations)

**Endpoint:**

```
GET /api/board/snapshot?date=YYYY-MM-DD
GET /api/board/snapshot?date=YYYY-MM-DD&refresh=1
```

- `date` = Honolulu calendar date (`yyyy-MM-dd`).
- No auth required.
- Response includes keys: `hr`, `hits`, `k`, `outs`, `nrfi`, `total`, `spread`, `ml`, `f5ml`, `f5spread`.
- Empty market = key present with `[]` (not missing key).
- HR/Hits candidate shape matches web `computeBatterBoard` output; snapshot may add `"_boardSummary"`.

**Representative HR/Hits candidate fields** (from live API):

`id`, `name`, `team`, `hand`, `order`, `score`, `simConfidence`, `avg`, `ops`, `slg`, **`hr` (Int)**, `hitRate`, `gamePk`, `gameLabel`, `propLine`, `lineupState`, `matchup`, …

**Decoding notes for future agents:**

- Use **`FlexibleString`** or similar when a stat may be string *or* number.
- **`LossyArray`** drops failed elements silently — always check DEBUG raw vs decoded counts when a tab looks empty but API has data.
- Game-market `line` already uses **`FlexibleValue`**.

---

## Known parity gaps (not blockers — optional follow-ups)

iOS Board HR/Hits is **functionally working**. Visual/UX differences vs web remain:

| Feature | Web | iOS (current) |
|---------|-----|----------------|
| Game grouping header (e.g. “STL @ NYM FINAL”) | Yes | Flat list |
| Result badges (HIT / NO HIT / HR on final games) | Yes | Partial / missing on prop cards |
| AI blurb (`_boardSummary`, “Hot — on a tear…”) | Yes | Not shown on card (field decoded as `boardSummary`) |
| LINEUP TBD badge for roster lineups | Yes | Check `lineupState` not wired in UI |

These are polish items, not data pipeline bugs.

---

## Investigation thread (historical docs in this repo)

Chronological debug notes — useful context, superseded by this doc for the final fix:

- `board-hr-hits-missing-keys.md`
- `board-hr-hits-still-empty-after-refresh.md`
- `board-hr-hits-root-cause-found.md` (web client-side compute discovery)
- `board-hr-hits-snapshot-vs-shared-board-mismatch.md`
- `board-hr-hits-mismatch-recurs-2026-06-11.md`
- `board-hr-hits-live-fallback-ios-feasibility.md`

---

## Rules for agents editing Board code

1. **Do not port `computeBatterBoard` to Swift** unless explicitly requested — server runs the same module as web.
2. **Primary data source:** `/api/board/snapshot` only.
3. **Empty markets:** use `&refresh=1` + 90s poll (see `BoardViewModel.loadAndPollIfNeeded`).
4. **Brand colors:** `Extensions/Color+Brand.swift` only — no hardcoded hex.
5. **New API type mismatches:** prefer `FlexibleValue` / `FlexibleString` over brittle `String?` fields.
6. **Backend changes** for board data → `ai-agent-mlb` repo, not this one.

---

## Quick smoke test checklist

- [ ] Login → Board → **Hits** — player cards with scores, AVG, OPS, L5 dots  
- [ ] Board → **HR** — same  
- [ ] Pull to refresh — no crash; data updates  
- [ ] DEBUG console — no `decoded count = 0` when `raw count > 0`  
- [ ] K / Outs / Games tabs still populate (regression)

---

## Related Codex tasks (already implemented — see `CODEX-HANDOFF.md`)

- `PickGradingEngine.swift` + `PicksViewModel.autoGrade()`
- AI Board log-pick prefill on `AIBoardEdgeCardView`
- `View+Shimmer.swift` + skeleton loading states

---

*Session completed 2026-06-11. iOS Board HR/Hits verified working against production Railway API.*
