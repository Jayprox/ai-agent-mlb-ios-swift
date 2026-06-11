# HR/Hits mismatch persists on a new date — fix did not resolve it

## Status

Re-tested against the newly-deployed backend per your note: "re-test... on a
day with some Final/confirmed games and confirm `hits`/`hr` now come back
populated, matching what the web's 'Shared daily board' shows."

Result: **same mismatch, new date.** This is not the "no confirmed lineups
yet" case — lineups ARE confirmed and the web has the data; the snapshot
endpoint does not.

## Evidence (2026-06-11, ~8:17 AM PDT / ~5:17 AM HI)

**iOS — raw JSON from `/api/board/snapshot?date=2026-06-11&refresh=1`**
(inspected via `JSONSerialization`, not a decode issue):

```
date = "2026-06-11"
hr.length   = 0
hits.length = 0
```

**Web app, same moment** — "Shared daily board" panel:

```
Shared daily board · snapshot Jun 11, 5:14 AM HI — same scores & text for
all users. Refreshes 10 AM HI + pregame.
```

Hits tab (STL @ NYM, 10:10 AM PDT), fully populated with `✓ CONFIRMED`
candidates:

- Alec Burleson (STL #3) — 78, 72% sim, .291 AVG / .835 OPS
- Jordan Walker (STL #4) — 77, 75% sim, .303 AVG / .926 OPS
- Iván Herrera (STL #2) — 69, 68% sim, .264 AVG / .805 OPS
- A.J. Ewing (NYM #5) — 66, 72% sim, .264 AVG / .687 OPS
- Carson Benge (NYM #1) — 62, ...
- (40/184 live, more below the fold)

The web's snapshot was generated at 5:14 AM HI — **3 minutes before** our
iOS request at ~5:17 AM HI — for the identical date, with confirmed lineups
already populated.

## Conclusion

The deploy referenced in your last message did not change this behavior:
`/api/board/snapshot?date=<today>&refresh=1` still returns `hr: []` /
`hits: []` even when the web's "Shared daily board" for the same date
already has confirmed, populated HR/Hits candidates generated minutes
earlier. This rules out "too early, no lineups yet" — the data demonstrably
exists for this date, just not via this endpoint/param combination.

## Ask

Same core question as before, now with a same-day, near-simultaneous repro:
**where does the web's "Shared daily board" Hits/HR panel get its data from
for `2026-06-11`, and how can `/api/board/snapshot?date=2026-06-11&refresh=1`
be made to return that same data?**

iOS doesn't need any further changes — `BoardSnapshot`/`BoardCandidate`
already decode `hr`/`hits` candidates the same as `k`/`outs` (confirmed via
raw JSON inspection above; the response shape isn't the issue, the content
is). Once the endpoint returns the same data the "Shared daily board" panel
shows, this should resolve immediately on the next poll/refresh.
