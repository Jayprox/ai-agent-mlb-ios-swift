# Lineup batSide Field — Verification Needed

## Issue
The iOS app is receiving `position` ✅ and `avg` ✅ from the lineup endpoint, but **`batSide` is still nil**.

## What We're Getting
```
First batter from /api/lineups/:gamePk response:
- name: James Wood ✅
- position: DH ✅
- avg: .258 ✅
- batSide: nil ❌
```

## What We Expected
Per the response file, `batSide` should be returning the batter's handedness:
- `"L"` for left-handed
- `"R"` for right-handed
- `"S"` for switch hitter

## Questions for Backend Team

1. **Was the change deployed?** Can you confirm the `/api/lineups/{gamePk}` endpoint is returning the updated response with `batSide`?

2. **Sample response needed:** Can you provide a sample JSON response for a game lineup so we can verify the exact field names and structure?

3. **Field name verification:** Is the field being sent as:
   - `batSide` (as specified)?
   - `hand` (if that's still the underlying field name)?
   - Something else?

## Current iOS Model
```swift
struct LineupBatter: Decodable {
    let name: String?
    let position: String?
    let batSide: String?      // ← looking for this exact field name
    let avg: String?
    
    enum CodingKeys: String, CodingKey {
        case name, position, batSide, avg
    }
}
```

If the backend is sending `hand` instead of `batSide`, we'll need to either:
- Option A: Update CodingKeys to map `batSide = "hand"`
- Option B: Backend confirms they're sending `batSide`

## Next Steps
Please provide a sample `GET /api/lineups/{gamePk}` response so we can verify the field names and update the iOS decoder if needed.
