# `/api/board/snapshot` returns empty HR/Hits while "Shared daily board" shows populated data — same date

## Status

The iOS implementation is complete and matches every spec from
`ios-board-hr-hits-fix.md`, `ios-board-snapshot-refresh-fix.md`, and
`ios-task-hr-hits-snapshot-refresh.md`:

- Polls `GET /api/board/snapshot?date=<today>` every ~75s while
  `snapshot.date == today` and any of the 10 markets is `[]`.
- Manual refresh (pull-to-refresh + "Check now" button) calls
  `GET /api/board/snapshot?date=<today>&refresh=1`.
- Decodes with the existing `BoardSnapshot` model — verified via raw JSON
  inspection that decoding is NOT the issue (see below).
- Empty-state messaging for HR/Hits is unchanged per spec.

This is no longer an iOS-side question. We have a reproducible, evidence-based
mismatch between two endpoints/views that should agree.

## Evidence

**1. Direct raw-JSON request from the iOS app**, at ~1:53 PM HI on 2026-06-10:

```
GET /api/board/snapshot?date=2026-06-10&refresh=1
```

Response (inspected via `JSONSerialization`, bypassing all Swift decoding):

```
date = "2026-06-10"
hr.length   = 0
hits.length = 0
```

So `date` correctly matches today, `&refresh=1` was applied, and `hr`/`hits`
are genuinely empty arrays in the raw response — not a decoding or shape
issue.

**2. The web app, at the same time (~1:53 PM HI / 4:53 PM PDT, same date)**,
shows the "Shared daily board" panel with:

- Header: `Shared daily board · snapshot Jun 10, 1:52 PM HI - same scores &
  text for all users. Refreshes 10 AM HI + pregame.`
- Hits tab: `17/20 hit`, fully populated with real candidates (Kevin
  McGonigle #1 — 72, Riley Greene #5 — 66, Gleyber Torres #2 — 64, Byron
  Buxton #2 — 62, Orlando Arcia #4 — 60, etc.), all marked `✓ CONFIRMED`.

Screenshot available on request — both panels were captured side-by-side at
the same timestamp.

## The discrepancy

For the same date (`2026-06-10`):

- `/api/board/snapshot?date=2026-06-10&refresh=1` → `hits: []`
- The web's "Shared daily board" (generated 1:52 PM HI, same date) → `hits`
  has 20 graded candidates, 17 hits.

Both can't be the canonical "snapshot for today." Possibilities:

1. **Two different stores.** The "Shared daily board" the web reads is a
   separately-cached blob (generated on its own schedule — "Refreshes 10 AM
   HI + pregame") that already has real `hr`/`hits` data, while
   `/api/board/snapshot` reads from a different store/cache that never got
   that data, or whose `hr`/`hits` were cleared.
2. **`&refresh=1`'s recompute is broken for `hr`/`hits`** and is overwriting
   (or returning, without persisting) `[]` instead of the existing
   "Shared daily board" data for those two markets specifically — note `k`
   and `outs` (pitcher markets) have returned real data throughout this whole
   investigation; only the two batter markets (`hr`, `hits`) are affected.
3. **`/api/board/snapshot` and the "Shared daily board" are intentionally
   different views**, and iOS should be calling a different
   endpoint/parameter to get the same data the web's Hits/HR tabs show.

## Ask

Given the "Shared daily board" clearly *has* populated `hr`/`hits` data for
2026-06-10 right now, can you point us at:

- the exact endpoint + params the web app calls to render that "Shared daily
  board" Hits/HR tabs, and
- whether `/api/board/snapshot?date=2026-06-10&refresh=1` is supposed to
  return that same data (and if so, why it's currently returning `[]` for
  `hr`/`hits` while `k`/`outs` are populated)?

iOS is ready to consume whichever endpoint/shape is correct — no model or
decoding changes are expected to be needed (the existing `BoardSnapshot`
model already handles `hr`/`hits` arrays of `BoardCandidate` the same as
`k`/`outs`). We just need to know where the populated data actually lives.
