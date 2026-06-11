# Board snapshot: `hr` and `hits` keys missing from `/api/board/snapshot`

## Symptom

In the iOS app, the Board tab's **HR** and **Hits** sub-tabs show "No board
data yet" while **K** and **Outs** populate normally (20 candidates each).
The web app, viewed around the same time, shows populated HR/Hits cards.

## Root cause (confirmed client-side)

This is **not an iOS decoding bug**. We added temporary diagnostics to the
iOS network layer to inspect the raw `/api/board/snapshot?date=...` response
and confirmed:

```
📦 board/snapshot[hr] key missing
📦 board/snapshot[hits] key missing
📦 board/snapshot[k] count = 20
📦 board/snapshot[outs] count = 20
```

- Request: `GET /api/board/snapshot?date=2026-06-10`
- Response top-level JSON simply has no `hr` or `hits` keys at all (not
  `null`, not `[]` — absent entirely).
- `k` and `outs` are present and populated with 20 candidates each, with the
  expected fields (`id`, `name`, `team`, `score`, `propLine`, etc.).
- The iOS decoder handles a missing key correctly (`decodeIfPresent` →
  `nil` → rendered as empty → "No board data yet"), so the client behavior
  is correct given this response.

## What to check on the backend

1. Confirm whether the snapshot generator for `2026-06-10` (and other
   recently-affected dates) actually computed `hr`/`hits` candidate lists,
   or skipped them.
2. If HR/Hits computation runs on a different schedule/condition than
   K/Outs (e.g., depends on batter prop lines being posted by books later in
   the day), confirm whether that's the case for this date/time and whether
   that's expected.
3. Confirm the web app is reading from the same `/api/board/snapshot`
   endpoint/response for HR/Hits, or whether it's getting that data from a
   different source/endpoint — if the latter, the iOS app may need to call
   that source instead.
4. If `hr`/`hits` are expected to always be present (even if empty `[]`)
   once the slate is generated, consider always including those keys in the
   response so the client can distinguish "not yet computed" from "computed,
   no candidates."

## Reference

- Endpoint: `GET /api/board/snapshot?date=YYYY-MM-DD`
- iOS model: `BoardSnapshot` in `Models/BoardModels.swift` expects optional
  arrays for `hr`, `hits`, `k`, `outs`, `total`, `ml`, `spread`, `nrfi`,
  `f5ml`, `f5spread`, plus `generatedAt`.
