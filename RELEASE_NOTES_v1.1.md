# Chalk That v1.1 Release Notes

**Release Date:** June 2026  
**Compatibility:** iOS 15.0+

---

## ✨ What's New

### iPad Support
- Full iPad optimization with native single-column layout
- Bottom navigation consistent across iPhone and iPad
- All features accessible on iPad: Slate, Board, AI Board, Picks, Chat, Model Picks, Predict, Scout, Settings

### Enhanced Slate Cards
- **Game Time** — Clear game start time display
- **Pitcher Handedness** — Starting pitchers with L/R indicators
- **Wind Direction** — Abbreviated compass format (e.g., "5mph W")
- **DOME Indicator** — Shows covered stadium games at a glance
- **NRFI Badges** — No Run First Inning lean with confidence level

### Picks Tab Improvements
- Complete prop information with market labels (e.g., "OVER 18.5 K")
- Cleaner card layout with removed duplicate headers
- Better prop visibility and data organization

---

## 🐛 Bug Fixes

- **LIVE Badge** — Fixed incorrect status for games not yet started
- **Optional Data Handling** — Improved reliability across all views
- **Dome Games Detection** — Fixed backend integration for covered stadiums

---

## 📱 Supported Devices

- iPhone 12 and later
- iPad (6th generation) and later

---

## 🔧 Technical Notes

- NavigationView updated for iPad multi-screen support
- WeatherData model includes isDome flag from backend
- Pitcher handedness integrated from probable pitchers data
- Wind direction compass algorithm optimized for space constraints
