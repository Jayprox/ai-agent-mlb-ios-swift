# Web/Backend Fix Request — Board Games lines missing in `/api/board/snapshot`

> **From:** iOS team (`ai-agent-mlb-ios-swift`)  
> **To:** Web + backend team (`ai-agent-mlb`)  
> **Date:** 2026-06-26  
> **Status:** Blocking Board > Games parity for `O/U`, `RL`, and `F5 RL`

---

## Problem

The iOS app can render the **lean** for Board > Games markets, but the
numeric line is missing for:

- `total` (`O/U`)
- `spread` (`RL`)
- `f5spread` (`F5 RL`)

Example current iOS behavior:

- `UNDER` with no `8.5`
- `OVER` with no `9.0`
- Team/run-line lean with no `-1.5` / `+1.5`

This is not a UI-only issue anymore. The iOS app already falls back to both:

1. `/api/board/snapshot?date=YYYY-MM-DD`
2. `/api/slate-bundle?date=YYYY-MM-DD`

and there is still no numeric value to display.

---

## What production is returning right now

### 1. `/api/board/snapshot` returns game candidates with no line

Observed on production for `date=2026-06-25`:

#### `total`

```json
{
  "lean": "UNDER",
  "line": null,
  "name": "OAK @ SF",
  "odds": {},
  "gameLabel": "OAK @ SF",
  "leanLabel": "UNDER ?"
}
```

#### `spread`

```json
{
  "lean": "HOME",
  "line": null,
  "name": "NYY @ BOS",
  "odds": {},
  "gameLabel": "NYY @ BOS",
  "leanAbbr": "BOS",
  "leanLabel": "BOS ?"
}
```

#### `f5spread`

```json
{
  "lean": "HOME",
  "line": "—",
  "name": "NYY @ BOS",
  "odds": {},
  "gameLabel": "NYY @ BOS",
  "leanAbbr": "BOS",
  "leanLabel": "BOS F5 RL —"
}
```

So the snapshot is carrying the recommendation but **not the actual betting
number**.

### 2. `/api/slate-bundle` also has no odds fallback

Observed on production for `date=2026-06-25`:

```json
{
  "oddsMap": null
}
```

That means iOS cannot recover the line from the slate bundle either.

---

## Why this matters

For these Board > Games cards, showing only the lean is incomplete:

- `UNDER` without `8.5` is ambiguous
- `BOS` without `-1.5` / `+1.5` is ambiguous
- `F5 RL` without a number is not actionable

The web UI appears to have access to these values in normal operation, and iOS
needs the backend contract to preserve them in JSON.

---

## Required fix

Please ensure that **at least one** of these backend responses provides the
actual line values for `total`, `spread`, and `f5spread`:

### Preferred: fix `/api/board/snapshot`

Each game-market candidate should include a usable numeric line in one of the
existing fields:

- `line`
- `odds.total`
- `odds.homeSpread` / `odds.awaySpread`
- `odds.f5HomeSpread` / `odds.f5AwaySpread`

### Acceptable fallback: restore `/api/slate-bundle` odds

If snapshot persistence intentionally omits lines, then `slate-bundle` needs a
non-null `oddsMap` with:

- `total`
- `awaySpread`
- `homeSpread`
- corresponding odds

so iOS can derive the same display line from live slate odds.

---

## Requested API contract

### `total` candidate

```json
{
  "lean": "UNDER",
  "line": 8.5,
  "odds": {
    "book": "DK",
    "total": "8.5",
    "underOdds": "-110",
    "overOdds": "-110"
  },
  "leanLabel": "UNDER 8.5"
}
```

### `spread` candidate

```json
{
  "lean": "HOME",
  "leanAbbr": "BOS",
  "line": -1.5,
  "odds": {
    "book": "DK",
    "homeSpread": "-1.5",
    "awaySpread": "+1.5",
    "homeSpreadOdds": "+105",
    "awaySpreadOdds": "-125"
  },
  "leanLabel": "BOS -1.5"
}
```

### `f5spread` candidate

```json
{
  "lean": "HOME",
  "leanAbbr": "BOS",
  "line": -0.5,
  "odds": {
    "book": "DK",
    "f5HomeSpread": "-0.5",
    "f5AwaySpread": "+0.5",
    "f5HomeSpreadOdds": "-115",
    "f5AwaySpreadOdds": "-105"
  },
  "leanLabel": "BOS F5 RL -0.5"
}
```

If true F5 spread numbers are unavailable from the odds provider, returning a
clear fallback value is still better than `null` / `?` / `—`.

---

## Production evidence used for this request

### `GET /api/board/snapshot?date=2026-06-25&refresh=1`

Observed:

- `total[*].line == null`
- `total[*].odds == {}`
- `total[*].leanLabel == "UNDER ?"` / `"OVER ?"`
- `spread[*].line == null`
- `spread[*].odds == {}`
- `spread[*].leanLabel == "BOS ?"` / similar
- `f5spread[*].line == "—"`
- `f5spread[*].odds == {}`

### `GET /api/slate-bundle?date=2026-06-25`

Observed:

- `oddsMap == null`

---

## iOS status

iOS already:

- reads `/api/board/snapshot`
- falls back to `/api/slate-bundle`
- tries multiple line fields (`propLine`, `suggestedLine`, `line`) where relevant

No further iOS logic change is needed once the backend returns real game lines
for these markets.

---

## Verification checklist

- [ ] `total` candidates return a usable numeric total line
- [ ] `spread` candidates return a usable run line
- [ ] `f5spread` candidates return a usable F5 run line (or explicit fallback)
- [ ] `leanLabel` no longer contains `?` or `—` for these markets when a line exists
- [ ] `slate-bundle` either restores `oddsMap` or snapshot itself carries enough data
- [ ] Production verification shared back with example payload snippet

---

## Message back to iOS when complete

Please reply with:

> Board Games lines fix deployed at [time].  
> Verified `total`, `spread`, and `f5spread` now return numeric lines in production.  
> Example: `OAK @ SF total -> UNDER 8.5`, `NYY @ BOS spread -> BOS -1.5`.

