# Backend Request: Dome Indicator in Weather Data

## Issue
Mobile app needs to display "DOME" badge for indoor games (e.g., Tropicana Field, Oracle Park).

Currently, we determine if a game is indoors by checking if `temp == nil`, but the weather API returns temperature data **even for dome games** (indoor temperature), so the `isDome` flag incorrectly returns false.

## Solution Needed
Add an explicit `isDome` boolean flag to the WeatherData response in the slate-bundle.

## Current WeatherData Response Shape
```json
{
  "temp": 76,
  "windspeed": 5.2,
  "winddirection": 247,
  "weathercode": 80,
  "precipitation_probability": 15
}
```

## Requested Change
Add `isDome` flag:

```json
{
  "temp": 76,
  "windspeed": 5.2,
  "winddirection": 247,
  "weathercode": 80,
  "precipitation_probability": 15,
  "isDome": false
}
```

For dome games (e.g., Tropicana Field, Oracle Park, Minute Maid Park), set `isDome: true`.

## Mobile Usage
```swift
struct WeatherData: Decodable {
    let temp: Double?
    let windspeed: Double?
    let winddirection: Double?
    let weathercode: Int?
    let precipitation_probability: Double?
    let isDome: Bool?  // ← NEW FIELD
    
    // Can then remove the computed property:
    // var isDome: Bool { temp == nil }  ← REMOVE THIS
}
```

## Impact
- Mobile app will display "DOME" badge correctly for indoor games
- Applied to Slate view cards and other game displays
- No breaking changes — field can be optional with default false

## Timeline
Needed before iPad release submission.

---

**MLB Domed/Retractable Roof Stadiums (reference):**
- Tropicana Field (TB) — Fixed dome
- Minute Maid Park (HOU) — Retractable roof
- Rogers Centre (TOR) — Retractable roof
- Retractable stadiums: T-Mobile Park (SEA), Safeco Field, etc.

(Note: Oracle Park in SF is open-air, not a dome)
