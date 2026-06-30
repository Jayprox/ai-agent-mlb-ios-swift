# Backend API Inquiry: Missing `resultHit` and `gradeStatus` Fields

## Issue Summary

The iOS app is loading 188 candidates from the board snapshot API, but **none have `resultHit` or `gradeStatus` populated**, even though MLB games are completed. This prevents the Finished filter and HIT/MISS badges from displaying graded picks.

---

## Current State

- **Total candidates loaded:** 188
- **Finished candidates (with resultHit or gradeStatus):** 0
- **Expected:** Completed games should have grading data available

---

## Technical Details

### What We're Looking For

```json
{
  "id": "12345",
  "name": "Juan Soto",
  "market": "hr",
  "gameLabel": "NYY @ BAL",
  "resultHit": true,      // ← Missing in all responses
  "gradeStatus": null,    // ← Missing in all responses
  "..."
}
```

### Where It's Used

1. **HIT/MISS Badges** — Shows on card when game is finished
2. **Finished Filter** — Filters board to show only graded picks
3. **Hit Stats** — Tracks successful picks across all markets

---

## Questions for Web Team

1. **Is the scoring/grading service running?**
   - Does a background job process completed games and populate `resultHit`?
   - What's the expected timeline? (Immediately after game ends? End of day?)

2. **Are these fields being stored in the database?**
   - Is the database schema set up for `resultHit` (boolean) and `gradeStatus` (string)?
   - Are they being populated correctly?

3. **Is the API returning these fields?**
   - Check if they're in the database but not being returned by the snapshot endpoint
   - Are they being filtered out anywhere in the API layer?

4. **Is there a separate grading endpoint?**
   - Should we call a different endpoint for grading results?
   - Or should they be included in the main `/board/snapshot` response?

5. **Test Case**
   - Can you check the API response for a completed game from today?
   - Send us the raw JSON to verify if `resultHit` and `gradeStatus` are present

---

## Impact

- ✅ Frontend filtering logic is correct and ready
- ✅ UI components (badges, filters) are implemented
- ⏳ Waiting on backend to populate grading data

Once `resultHit` and `gradeStatus` start flowing through the API, these features will work automatically without any frontend changes.

---

## Testing

To reproduce:
1. Load Board view on iOS app
2. Open Xcode Console
3. Look for diagnostic output:
   ```
   🏁 FINISHED GAMES DIAGNOSTIC
      Total candidates: 188
      Finished candidates: 0
      ⚠️ NO FINISHED GAMES FOUND
   ```

---

**Requested By:** iOS v1.2 Development  
**Date:** June 30, 2026  
**Scope:** All markets (HR, Hits, K, Outs, Games)
