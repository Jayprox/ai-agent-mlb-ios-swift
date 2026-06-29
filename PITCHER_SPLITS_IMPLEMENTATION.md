# Pitcher Splits Implementation for iOS App

## Overview
We've added pitcher splits (VS LHH / VS RHH) to the Game Overview tab in the iOS app. The feature displays expanded pitcher statistics against left-handed and right-handed hitters.

## What's New

### Display
The pitcher card now shows two split blocks below the main pitcher stats:

**VS LHH Block:**
- AVG (batting average against)
- OPS (on-base plus slugging)
- K/9 (strikeouts per 9 innings)
- BB/9 (walks per 9 innings)

**VS RHH Block:**
- AVG
- OPS
- K/9
- BB/9

### UI Changes
- Split blocks appear in a side-by-side layout below the pitcher's main stats
- Labels are small and dimmed
- Stats are color-coded (K/9 in cyan for emphasis)
- Each stat shows label on left, value on right

## Backend Requirements

### Endpoint
**GET** `/api/pitcher-splits/{pitcherId}`

### Expected Response Format
```json
{
  "pitcherId": 12345,
  "vsLeft": {
    "avg": ".268",
    "ops": ".724",
    "k9": "9.2",
    "bb9": "2.1"
  },
  "vsRight": {
    "avg": ".245",
    "ops": ".681",
    "k9": "8.8",
    "bb9": "1.9"
  }
}
```

### Model Definition
```swift
struct PitcherSplits: Decodable {
    let pitcherId: Int?
    let vsLeft: SplitLine?
    let vsRight: SplitLine?

    struct SplitLine: Decodable {
        let avg: String?
        let ops: String?
        let k9: String?
        let bb9: String?
    }
}
```

**Note:** All stats should be returned as strings. The app handles the display formatting.

## iOS Implementation

### Files Modified
1. **GameOverviewView.swift**
   - Updated pitcher card to display splits
   - Enhanced `splitBlock()` function to show 4 stats (AVG, OPS, K/9, BB/9)

2. **GameDetailViewModel.swift**
   - Already fetching splits via `awayPitcherSplits` and `homePitcherSplits`
   - `currentSplits` computed property returns the selected pitcher's splits

### Data Flow
```
GameDetailView loads game
  ↓
GameDetailViewModel.load() called
  ↓
Fetches /api/pitcher-splits/{awayPitcherId} → awayPitcherSplits
Fetches /api/pitcher-splits/{homePitcherId} → homePitcherSplits
  ↓
GameOverviewView uses vm.currentSplits
  ↓
Displays VS LHH / VS RHH blocks if data exists
```

## Status
- ✅ iOS UI implemented and ready
- ⏳ Waiting for backend endpoint: `/api/pitcher-splits/{pitcherId}`

## Contact
Once the endpoint is implemented with the model structure above, the iOS app will automatically display the pitcher splits data.
