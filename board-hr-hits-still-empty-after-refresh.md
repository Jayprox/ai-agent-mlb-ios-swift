# HR/Hits still empty after `&refresh=1` — confirmed genuinely `[]`

## Status

The iOS-side fix from `ios-board-snapshot-refresh-fix.md` is implemented and
working as designed:

- `BoardSnapshot` distinguishes "missing" vs "present but `[]`" per market.
- On load, if `hr`/`hits` are `[]`, the app polls
  `GET /api/board/snapshot?date=<today>` every ~75s.
- A "Check now" button calls `GET /api/board/snapshot?date=<today>&refresh=1`
  immediately, with a loading state.
- Empty HR/Hits now show a distinct "Lineups not yet posted / Check back
  closer to first pitch" message instead of the generic "No board data yet".

## What we found

We added a temporary diagnostic to inspect the raw response after tapping
"Check now" (i.e. with `&refresh=1`). Result:

```
📦 board/snapshot[hr] raw count = 0
📦 board/snapshot[hits] raw count = 0
```

Both arrays are **genuinely empty (`[]`) in the raw JSON**, not a decoding
issue — `LossyArray` isn't dropping anything; there's nothing to drop. So
`&refresh=1` ran but `computeBatterBoard` returned `[]` again.

## Question for the backend/web team

Per `ios-board-hr-hits-bug.md` (the very first doc in this thread), the web
app shows "LINEUP TBD" cards for batters even when no confirmed lineup
exists yet, by computing roster-based candidates client-side. Per
`ios-board-snapshot-refresh-fix.md`, the server-side `computeBatterBoard`
(used by `/api/board/snapshot`) does **not** do this — it apparently returns
`[]` when there's no confirmed lineup.

Given that, two real possibilities:

1. **This is correct/expected right now** — at the time we tested, no game
   today has a confirmed-or-roster lineup yet, so `[]` is accurate, and the
   new "Lineups not yet posted" message is the right UX. In that case there's
   nothing more to do; the tab should self-heal via polling once lineups
   post.
2. **`computeBatterBoard` should also produce roster-based "LINEUP TBD"
   candidates** (matching the web app's client-side behavior) so
   `/api/board/snapshot` returns real (if provisional) HR/Hits candidates
   even before lineups are confirmed. If so, that's a backend change to
   `computeBatterBoard` — iOS doesn't need any changes since it already
   decodes whatever shape comes back (assuming it matches `BoardCandidate`'s
   fields: `id`/`name`/`score`/etc., not the `entityId`/`playerName`/nested
   `stats` shape from the earlier reference doc).

Can you confirm which of these is the case for the date/time we tested
(today, ~4:20 PM HI), and if it's #2, let us know once that's deployed so we
can verify the cards show up?
