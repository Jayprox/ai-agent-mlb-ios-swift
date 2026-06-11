# Root cause found: web's HR/Hits board is computed client-side, not from `/api/board/snapshot`

## TL;DR

`/api/board/snapshot` was never the source of the web's populated HR/Hits
data. The web computes HR/Hits client-side in the browser from raw data
endpoints. Every fix applied to `/api/board/snapshot` (TASK 145–148) was
correct *for that endpoint* but irrelevant to what the web's HR/Hits tabs
actually display — which is why the mismatch survived all of them.

## How this was found

Loaded `https://ai-agent-mlb-production.up.railway.app` in a real browser,
navigated to Board → Hits (which rendered fully populated, `✓ CONFIRMED`
candidates — same "Shared daily board, snapshot Jun 11, 10:00 AM HI" panel
seen in prior screenshots), then inspected
`performance.getEntriesByType('resource')` for every network request made by
the page since load (59 total).

**Result: zero requests to `/api/board/snapshot` or anything containing
"board" or "snapshot".**

What the page *does* call (per game, on the Board/Hits view):

- `/api/players/{id}/stats?group=pitching`
- `/api/players/{id}/gamelog?group=pitching`
- `/api/lineups/{gamePk}`
- `/api/nrfi/{gamePk}`
- `/api/odds`
- `/api/schedule`
- `/api/injuries`
- `/api/picks`
- `/api/auth/preferences`

The HR/Hits cards (player names, AVG/OPS, sim %, score, "Hot — on a tear
recently" blurbs, lineup spot, confirmed badges) are assembled from these
in-browser — i.e. exactly the `computeBatterBoard`/`computePitcherBoard`
client-side logic described in the original `ios-board-hr-hits-bug.md`.

## Why this explains the whole thread

- `board-hr-hits-missing-keys.md` → `ios-board-hr-hits-fix.md` →
  `ios-board-snapshot-refresh-fix.md` → `ios-task-hr-hits-snapshot-refresh.md`
  → TASK 148 all correctly diagnosed and fixed real bugs *in
  `/api/board/snapshot`* (missing keys, negative-cache/timeout handling,
  persistence of recomputed markets). Each fix was verified and deployed.
- But after every single one, `/api/board/snapshot?date=<today>&refresh=1`
  still returned `hr: []` / `hits: []` while the web showed populated data —
  because the web was never reading from this endpoint for HR/Hits in the
  first place. The endpoint fixes were real, just not connected to what the
  web displays.
- The original feasibility doc (`board-hr-hits-live-fallback-ios-feasibility.md`)
  was on the right track — it just got redirected by
  `ios-task-hr-hits-snapshot-refresh.md`'s claim that
  "`/api/board/snapshot` already has everything needed... don't port
  `computeBatterBoard`/`computePitcherBoard` to Swift." That claim is what
  needs revisiting.

## What iOS needs

iOS cannot replicate this — `computeBatterBoard`/`computePitcherBoard` pull
from ~9 different endpoints per game (player stats, gamelogs, lineups, NRFI,
odds, schedule, injuries) and assemble scores/sims/blurbs client-side in JS.
Porting that to Swift would be a major, ongoing-maintenance undertaking (this
was the conclusion of the original feasibility doc, and it still holds).

**The fix needs to be server-side**: either

1. A new endpoint (e.g. `/api/board/live` or similar) that runs the same
   `computeBatterBoard`/`computePitcherBoard` logic the web's frontend runs,
   server-side, and returns the result as JSON in the existing
   `BoardSnapshot`/`BoardCandidate` shape — iOS calls this for `hr`/`hits`
   (and any other markets the web computes client-side), or
2. `/api/board/snapshot` itself is changed to run/persist this same
   client-side computation for `hr`/`hits` server-side (effectively moving
   the web's client-side `computeBatterBoard` logic into the backend job that
   populates the snapshot).

Either way, no further iOS changes are needed until one of these exists —
the current implementation already polls/refreshes `/api/board/snapshot`
correctly and will pick up real data the moment that endpoint returns it.

## Suggested message to the backend/web team

> We found the root cause of the HR/Hits mismatch: the web's Board → Hits/HR
> tabs don't call `/api/board/snapshot` at all — confirmed via browser
> network inspection (59 requests on page load + Board/Hits navigation, zero
> to `/board/snapshot`). The populated data comes from client-side JS
> (`computeBatterBoard`/`computePitcherBoard`) using `/api/players/*/stats`,
> `/api/players/*/gamelog`, `/api/lineups/*`, `/api/nrfi/*`, `/api/odds`,
> `/api/schedule`, `/api/injuries`. The TASK 145–148 fixes to
> `/api/board/snapshot` are real fixes but don't affect what the web shows
> for HR/Hits, which is why iOS still sees `[]` after every deploy. Can you
> either (a) add an endpoint that runs the same client-side computation
> server-side and returns JSON, or (b) have `/api/board/snapshot` persist
> that same computation for `hr`/`hits`? iOS is ready to consume either as
> soon as it exists.
