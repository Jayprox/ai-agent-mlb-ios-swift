# TASK 149 re-test results: `/api/board/snapshot` refresh → wait 60-90s → re-fetch

Ran the exact 2-step test requested, live against production, via an
authenticated `fetch()` in the browser session (same session showing the
populated "Shared daily board" Hits tab).

## Results

**Step 1 — `GET /api/board/snapshot?date=2026-06-11&refresh=1`**
- `date`: `2026-06-11`
- `generatedAt`: `2026-06-11T21:38:57.986Z` (~11:38:58 AM HI)
- `hits.length`: `0`
- `hr.length`: `0`
- Called at: `2026-06-11T21:45:27.907Z` (~11:45:28 AM HI)

**Wait**: ~80 seconds

**Step 3 — `GET /api/board/snapshot?date=2026-06-11`** (no refresh)
- `date`: `2026-06-11`
- `generatedAt`: `2026-06-11T21:45:27.729Z` (~11:45:28 AM HI)
- `hits.length`: `0`
- `hr.length`: `0`
- Called at: `2026-06-11T21:47:12.609Z` (~11:47:13 AM HI)

## What this shows

A recompute **did** happen — `generatedAt` advanced from `21:38:57.986Z` to
`21:45:27.729Z`, and that new timestamp lines up almost exactly with step 1's
call time (`21:45:27.907Z`). So step 1's `&refresh=1` triggered a fresh
recompute that completed and persisted within the 80s window.

But the freshly recomputed snapshot still has `hits: []` and `hr: []`.

Also checked the response shape directly — top-level keys are exactly the
standard 10 markets (`hits, hr, k, outs, nrfi, total, spread, ml, f5ml,
f5spread`) plus `date`/`generatedAt`, no extra `_emptyMarketAt`/error/meta
fields to indicate *why* those two are empty.

For comparison: the web's Hits tab (via the `sharedMarketOrLive` fallback) is
showing live, confirmed candidates for this same date/time right now.

## Conclusion (per TASK 149's own decision tree)

Step 3 is still empty → **this is a backend logic bug in
`computeBatterBoard`/`gatherLiveBoardData`/`computeMarketCandidates`**
returning `[]` server-side even though a fresh recompute ran and live data
clearly exists (the web's fallback is using it right now). Not a
routing/caching/timing issue — the recompute fired and persisted, and still
produced `[]`.

Per TASK 149: next step is server-side targeted logging in
`computeBatterBoard`/`gatherLiveBoardData`/`computeMarketCandidates` to see
exactly what's empty for `hr`/`hits` (lineups not confirmed in the *server's*
view? hitting logs missing? a filter dropping all candidates?) — even though
the same data is clearly available to the client-side path.

No iOS changes made or needed for this step.
