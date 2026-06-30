# Grading Data Implementation — Backend Response Applied

## Summary of Changes

Based on the backend team's response, we've updated the iOS implementation to align with the actual API contract and grading architecture.

---

## What Changed

### 1. BoardCandidate Model (`BoardModels.swift`)

**Removed:**
- `gradeStatus: String?` — This field doesn't exist on board candidates; it's picks-only

**Added:**
- `actualStat: Double?` — The real stat the player posted (e.g., 7 Ks, 2 hits)
- `resolvedAt: String?` — ISO timestamp when grading was written; `null` if not yet graded

**Updated `CodingKeys`:**
```swift
case resultHit, actualStat, resolvedAt
```

### 2. Computed Properties

**`gradeIsHit`** — Now checks `resolvedAt != nil` instead of `gradeStatus == nil`
```swift
var gradeIsHit: Bool? {
    guard resolvedAt != nil else { return nil }
    return resultHit
}
```

**`isFinished`** — Now checks `resolvedAt != nil` instead of checking for `gradeStatus`
```swift
var isFinished: Bool {
    resolvedAt != nil
}
```

### 3. HIT/MISS Badge Logic (`BoardCandidateCardView.swift`)

**Removed:**
- gradeStatus badge rendering

**Updated `resultBadge`:**
- Only shows badges for **player prop markets** (HR, Hits, K, Outs)
- **Games tab cards will never show badges** — they're not snapshotted by the backend
- Removed the gradeStatus check entirely

```swift
@ViewBuilder
private var resultBadge: some View {
    // Only show for player props; Games tab isn't snapshotted
    if !candidate.isGameMarket, let hit = candidate.resultHit {
        Text(hit ? "HIT ✓" : "MISS ✗")
            // ...
    }
}
```

### 4. Diagnostics (`BoardViewModel.swift`)

**Updated `diagnoseFinishedGames()`:**
- Now logs `actualStat` instead of `gradeStatus`
- Updated messaging to explain grading timeline
- Suggests testing with past dates

---

## How Grading Works

1. **Timeline:** Nightly at **1 AM & 2 AM Hawaii time** (UTC−10)
2. **Target Date:** Grading runs on **yesterday's date** — not today
3. **Data:** Once graded, `resultHit`, `actualStat`, and `resolvedAt` are populated
4. **Markets:** Only **HR, Hits, K, Outs** are snapshotted; Games tab cards are not graded

Example API response after grading:
```json
{
  "id": "...",
  "name": "Juan Soto",
  "market": "hr",
  "resultHit": true,
  "actualStat": 1,
  "resolvedAt": "2026-07-01T09:14:22.000Z"
}
```

---

## How to Test

### Option 1: Use a Past Date (Easiest)

Request a completed past date that's already been graded:

```
GET /api/board-snapshot/2026-06-29
```

On the iOS app, you can't change the date yet, but the backend will return graded data for that date via the endpoint.

### Option 2: Manual Force-Grade (Admin)

Use the admin endpoint to force-grade a specific date on demand:

```
GET /api/admin/jobs/resolve-card-snapshots?date=2026-06-29
Header: x-admin-secret: <ADMIN_SECRET>
```

Response:
```json
{ "ok": true, "date": "2026-06-29", "resolved": 12, "skipped": 3 }
```

### Option 3: Wait for Tomorrow

If testing with today's date (June 30):
- Games must be **final** first
- Grading runs at **1 AM & 2 AM Hawaii time** next morning (July 1)
- By ~9 AM Hawaii, all graded data should be available

---

## Console Output (Debug)

When the Board loads, check Xcode Console for:

```
🏁 GRADING STATUS DIAGNOSTIC
   Player prop candidates (HR/Hits/K/Outs): 188
   Graded candidates: 0
   ℹ️ No graded games yet
   Grading runs nightly at 1 AM & 2 AM Honolulu time
   To test: Use a past date like 2026-06-29 instead of today
```

Once grading is available:
```
🏁 GRADING STATUS DIAGNOSTIC
   Player prop candidates (HR/Hits/K/Outs): 188
   Graded candidates: 45
   Graded games:
   - [HR] Aaron Judge — resultHit: true, actualStat: 1
   - [Hits] Juan Soto — resultHit: false, actualStat: 1
   ... and 43 more
```

---

## What's NOT Snapshotted

Per backend team: **Games tab cards (NRFI, O/U, RL, ML) are not snapshotted and will never be graded.**

This means:
- ❌ No HIT/MISS badges on Games tab (by design)
- ❌ Games tab won't populate the Finished filter
- ✅ Player prop markets (HR/Hits/K/Outs) will still work correctly

---

## Next Steps

1. ✅ Model updated to match API contract
2. ✅ Badges only show for player props
3. ✅ Diagnostics updated to guide testing
4. ⏳ Test with a past date to verify grading data flows through
5. ⏳ Confirm Finished filter shows graded games for player props

---

## References

- Backend Response: `BACKEND_GRADING_RESPONSE.md`
- Grading Job: `backend/jobs/resolveCardSnapshotsJob.js`
- Database Table: `board_card_snapshots`
- Fields: `result_hit` (boolean), `actual_stat` (numeric), `resolved_at` (timestamp)

---

**Implementation Date:** June 30, 2026  
**Status:** Ready for testing
