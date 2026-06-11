# HR/Hits empty-snapshot fallback: iOS feasibility notes

## TL;DR

The "shared empty array overrides live fallback" bug is real, but the
**recommended iOS-side fix as written isn't directly portable** — iOS has no
local equivalent of `computeBatterBoard`, and doesn't currently fetch the
inputs that function needs. The smallest fix that keeps both apps consistent
is a tiny **new backend endpoint** that runs the existing
`computeBatterBoard`/`computePitcherBoard` server-side and returns
`BoardCandidate`-shaped JSON. iOS can then add a simple "if shared snapshot
market is empty, call the live endpoint" fallback — a small, low-risk client
change, since the response shape already matches what `BoardSnapshot` expects.

## What we checked on the iOS side

- iOS has `Models/WhyFactorsBuilder.swift`, which does client-side scoring —
  but only as an **explanation generator** for the "Why?" modal on a
  candidate that already exists. It decomposes an existing `BoardCandidate`'s
  score into labeled signals (Power, HR Pace, Park, Wind, Batting Order,
  etc.). It does not generate new candidates from raw data.
- No view model (`AIBoardViewModel`, `PredictViewModel`, `ModelPicksViewModel`,
  `BoardViewModel`) builds a candidate list from scratch — they all consume
  pre-computed lists from the backend (`/api/board/snapshot`,
  `/api/ai-board/edges`).
- There is **no Swift equivalent of `computeBatterBoard`**.

## What `computeBatterBoard` needs (per `prop-scout-handoff.md`)

```js
computeBatterBoard(type, liveSlate, liveLineups, liveWeather,
                    livePlayerProps, liveHittingLog, liveStatSplits)
```

Inputs: live slate/schedule, confirmed lineups (with scratches), wind/weather,
player prop lines, recent hitting logs (L5 hit rate), and stat splits
(AVG/OPS/SLG/HR totals) — plus shared helpers (`normalizeScratchName`,
`vigStrip`, `propEdgeData`, park factors, umpire stats) from `src/board/index.js`.

iOS's existing endpoints (`slate-bundle`, `linescore`/`boxscore`, per-game
Lineup/Props/Intel) don't provide these as a single slate-wide bundle the way
the web app's live state does. Reimplementing this in Swift would mean:

- Adding several new slate-wide fetches (lineups, hitting logs, player props,
  stat splits) that don't currently exist as iOS endpoints.
- Porting all of `computeBatterBoard`'s scoring/scratch/park/wind/cap logic
  from JS to Swift.
- Keeping that logic in sync with the web app's version going forward
  (duplicate maintenance).

That's a meaningfully larger effort than the original snapshot bug, and risks
the two clients drifting out of sync on scoring.

## Suggested approach instead

Since `computeBatterBoard` / `computePitcherBoard` already exist and are
tested server-side (`src/board/index.js`):

1. Add a small endpoint, e.g. `GET /api/board/live?date=YYYY-MM-DD&market=hr|hits`
   (or extend `/api/board/snapshot` with a `?live=hr,hits` param), that runs
   the relevant `compute*Board` function server-side using current live data
   and returns the result in the **same `BoardCandidate` JSON shape** as the
   snapshot.
2. iOS adds the same selection rule the web app now uses, but calling this
   endpoint instead of a local function:
   - shared market missing → call live endpoint
   - shared market non-empty → use shared
   - shared market `[]` → call live endpoint; if it returns candidates, use
     those, otherwise show the empty state
3. Because the response shape matches `BoardCandidate`, no new iOS decoding
   model is needed — just an extra `APIClient` call in `BoardViewModel.load()`
   (or on-demand when a tab is empty) and a small selection helper mirroring
   `sharedMarketOrLive` from the web fix.

This keeps the scoring logic in one place (backend), avoids duplicating
`computeBatterBoard` in Swift, and gives iOS the same "no more permanently
blank HR/Hits" behavior with a contained client change once the endpoint
exists.

## Open question for the backend/web team

Is adding `GET /api/board/live?date=...&market=hr|hits` (or a `?live=` param
on the existing snapshot endpoint) feasible? If so, iOS can implement the
fallback call + selection logic once that's available.
