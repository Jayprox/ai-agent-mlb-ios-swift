# Prop Scout — iOS Swift Handoff

## Project Overview

Prop Scout is a personal MLB sports betting research app. This document covers
the iOS native app built in Swift/SwiftUI. The backend is already live on
Railway — the iOS app is a new client consuming the same REST API.

**Web app repo:** `ai-agent-mlb`  
**iOS app repo:** `ai-agent-mlb-ios-swift` (this repo)  
**Backend base URL (prod):** Railway deployment (see `PROP_SCOUT_API.md`)  
**Backend base URL (local):** `http://localhost:3001`

---

## Decisions Made

| Decision | Choice |
|----------|--------|
| UI framework | SwiftUI |
| Architecture | MVVM + `async/await` |
| Networking | `URLSession` (no third-party library) |
| Auth storage | Keychain (JWT token) |
| Minimum iOS | iOS 16 |
| Device target | iPhone only (MVP) |
| Feature scope | Core MVP first → Full Parity later |
| Design direction | Hybrid — dark brand palette + native SwiftUI patterns |
| Push notifications | Phase 2 (after MVP) |
| WidgetKit | Phase 2 (after MVP) |
| Repo structure | Separate repo from web app |

---

## MVP Scope

### ✅ In MVP

| Screen | Notes |
|--------|-------|
| Login / Auth | Keychain JWT, username + password |
| Slate (game list) | Today's games, live scores, LIVE/FINAL badges |
| Board | HR / Hits / K / Outs / Games tabs, shared daily snapshot |
| Why? modal | Factor breakdown sheet per card |
| Picks tab | Log picks, auto-grade, record, P&L, collapsible dates |
| Log Pick sheet | Side/odds/units, pre-filled from card |
| Settings (minimal) | Preferred book + sign out |

### ⏳ Phase 2 (post-MVP)

- Game detail view (Overview, Lineup, Props, Intel, Boxscore tabs)
- Model tab
- AI Board tab
- Predict tab
- Chat tab
- Push notifications (APNs — pick graded, game goes live)
- WidgetKit home screen widget (today's record + live picks)
- Face ID / Touch ID login
- iPad support

---

## Tech Stack

```
Language:     Swift 5.9+
UI:           SwiftUI
Architecture: MVVM
Networking:   URLSession + async/await
Auth:         JWT stored in Keychain (Security framework)
Min iOS:      16.0
Xcode:        15+
```

No third-party dependencies needed for MVP. Add only if there's a clear
justified need.

---

## Project Structure

```
PropScout/
├── PropScoutApp.swift              # App entry point, root NavigationStack
├── Network/
│   ├── APIClient.swift             # URLSession wrapper, base URL, auth header
│   ├── Endpoints.swift             # All endpoint path constants
│   └── KeychainManager.swift       # JWT read/write/delete via Security framework
├── Models/                         # Codable structs matching API JSON shapes
│   ├── SlateGame.swift
│   ├── BoardCandidate.swift
│   ├── Pick.swift
│   ├── LiveScore.swift
│   └── User.swift
├── ViewModels/
│   ├── AuthViewModel.swift         # Login state, token management
│   ├── SlateViewModel.swift        # Slate + live score polling
│   ├── BoardViewModel.swift        # Board snapshot, tab switching
│   └── PicksViewModel.swift        # Picks CRUD, grading
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Slate/
│   │   ├── SlateView.swift         # Game list
│   │   └── SlateCardView.swift     # Individual game card
│   ├── Board/
│   │   ├── BoardView.swift         # Tab switcher (HR/Hits/K/Outs/Games)
│   │   ├── BatterCardView.swift    # HR + Hits card
│   │   ├── PitcherCardView.swift   # K + Outs card
│   │   ├── GameCardView.swift      # Games tab card
│   │   └── WhyModalView.swift      # Factor breakdown sheet
│   ├── Picks/
│   │   ├── PicksView.swift         # Picks list, date sections, stats tiles
│   │   ├── PickCardView.swift      # Individual pick row
│   │   └── LogPickSheet.swift      # Add pick bottom sheet
│   ├── Settings/
│   │   └── SettingsView.swift      # Preferred book + sign out
│   └── Shared/
│       ├── LiveBadge.swift         # Pulsing red LIVE badge (reused everywhere)
│       ├── MarketBadge.swift       # K / HR / Hits / ML etc colour chips
│       ├── ResultBadge.swift       # HIT / MISS / PENDING / PPD / SCRATCH
│       └── Color+Brand.swift       # Brand dark palette as Color extensions
└── Extensions/
    ├── Date+Slate.swift            # Date formatting helpers
    └── View+Shimmer.swift          # Loading skeleton effect (optional)
```

---

## Authentication

### Flow

1. `POST /api/auth/login` with `{ username, password }`
2. Response: `{ token: "<jwt>", userId, username, role }`
3. Store `token` in Keychain under key `"prop_scout_jwt"`
4. Every authenticated request: `Authorization: Bearer <token>` header

### Keychain pattern

```swift
// KeychainManager.swift
static func saveToken(_ token: String) { ... }
static func loadToken() -> String? { ... }
static func deleteToken() { ... }
```

### Auth endpoints

```
POST /api/auth/login    { username, password }  → { token, userId, username, role }
POST /api/auth/logout   (no body)               → { ok: true }
GET  /api/auth/me                               → { userId, username, role }
```

---

## Key API Endpoints for MVP

See `PROP_SCOUT_API.md` (in `ai-agent-mlb` repo) for full shapes. Summary:

### Slate
```
GET /api/slate-bundle?date=YYYY-MM-DD
```
Single call returns schedule + odds + nrfi + weather. Use this instead of
individual calls. Response: `{ schedule, oddsMap, nrfiMap, weatherMap }`.

### Board
```
GET /api/board/snapshot?date=YYYY-MM-DD
```
Returns pre-scored board candidates for all markets. Response:
`{ hr: [...], hits: [...], k: [...], outs: [...], total: [...], ml: [...], spread: [...], nrfi: [...], generatedAt }`.
Each candidate has `id`, `name`, `score`, `gamePk`, `gameLabel`, `lean`,
`bookLine`, `_boardSummary` (AI summary text), `market`.

### Live scores (poll every 60s for live games)
```
GET /api/linescore/:gamePk
```
Response: `{ inning, halfInning, awayScore, homeScore, away: { abbr, runs }, home: { abbr, runs }, innings: [...] }`

### Picks
```
POST   /api/picks                → log a pick
GET    /api/picks?days=N         → fetch picks list
GET    /api/picks/stats?days=N   → wins/losses/pending/hitRate/totalPnl
PATCH  /api/picks/:id/void       → void a pick
PATCH  /api/picks/:id/grade      → write result_hit, actual_stat, grade_status
```

### Boxscore (for pick grading)
```
GET /api/boxscore/:gamePk
```
Returns `{ batting: { away: [...], home: [...] }, pitching: { away: [...], home: [...] }, linescore: { innings, away.runs, home.runs }, isFinal }`.

---

## Pick Grading Logic (port from web app)

The iOS app should grade picks client-side and write results via
`PATCH /api/picks/:id/grade`. Same logic as the web app's `gradePickLocally`:

**Game picks** (`ml`, `spread`, `total`, `nrfi`, `f5ml`, `f5spread`):
- `pick.playerId` = the gamePk (stored as String)
- Use linescore for scores, innings array for NRFI/F5

**Prop picks** (`k`, `outs`, `hr`, `hits`):
- `pick.playerId` = MLB player ID
- Fetch boxscore and find player by ID in batting/pitching arrays
- **SCRATCH**: player not in boxscore at all → `gradeStatus = "scratch"`

**grade_status values:**
- `nil` → resolved (hit or miss)
- `"ppd"` → game postponed/cancelled
- `"scratch"` → player didn't play
- `"push"` → exact line hit

**P&L formula:**
- Win with odds: `units × (odds/100)` if positive, `units × (100/|odds|)` if negative
- Win without odds: `+units` (flat)
- Loss: `-units`

---

## Board Data Model

The Board snapshot returns candidates per market. Key fields on each candidate:

```swift
struct BoardCandidate: Codable {
    let id: String               // composite "market:playerId:gamePk" or plain playerId
    let entityId: String?        // plain MLB player ID (use this for liveBoardResults lookup)
    let name: String
    let team: String?
    let gamePk: Int
    let gameLabel: String
    let gameTime: String?        // ISO8601
    let market: String           // "hr", "hits", "k", "outs", "ml", etc.
    let score: Int               // 0–100 algorithmic score
    let lean: String?            // "OVER", "UNDER", "HOME", "AWAY", "NRFI"
    let leanAbbr: String?        // team abbreviation for game markets
    let bookLine: Double?
    let _boardSummary: String?   // AI summary text
    // batter-specific
    let avg: String?
    let ops: String?
    let hitRate: [Int?]?         // last 5 games: 1=hit, 0=no hit, nil=unknown
    // pitcher-specific
    let avgK3: Double?
    let avgIP: Double?
    let era: String?
    let whip: String?
}
```

---

## Live Game Status

Game status strings from `/api/schedule`:
- `"Preview"` / `"Scheduled"` / `"Pre-Game"` → upcoming
- `"Warmup"` / `"In Progress"` → live
- `"Final"` / `"Game Over"` / `"Completed Early"` → final
- `"Postponed"` / `"Cancelled"` / `"Suspended"` → PPD

The schedule cache can be stale by up to 1 hour. Use linescore polling
(every 60s for games past their scheduled start time) to detect live status
earlier. If `linescore.inning` is a valid integer and game is not already
marked Final → treat as live.

---

## Dark Brand Color Palette

```swift
// Color+Brand.swift
extension Color {
    static let brandBackground    = Color(hex: "#0b0c17")
    static let brandSurface       = Color(hex: "#161827")
    static let brandSurface2      = Color(hex: "#1a1c2e")
    static let brandBorder        = Color(hex: "#1f2437")
    static let brandBorder2       = Color(hex: "#2d3148")
    static let brandText          = Color(hex: "#f9fafb")
    static let brandTextMuted     = Color(hex: "#9ca3af")
    static let brandTextDim       = Color(hex: "#6b7280")
    static let brandGreen         = Color(hex: "#22c55e")
    static let brandAmber         = Color(hex: "#fbbf24")
    static let brandRed           = Color(hex: "#ef4444")
    static let brandBlue          = Color(hex: "#3b82f6")
    static let brandPurple        = Color(hex: "#a78bfa")
    static let brandCyan          = Color(hex: "#38bdf8")
}
```

---

## Market Labels & Colors

```swift
// Match the web app's MARKET_COLORS and MARKET_LABELS
let marketMeta: [String: (label: String, color: Color)] = [
    "hr":     ("HR",     .brandAmber),
    "hits":   ("Hits",   Color(hex: "#fb923c")),
    "k":      ("K",      .brandCyan),
    "outs":   ("Outs",   .brandPurple),
    "ml":     ("ML",     Color(hex: "#34d399")),
    "spread": ("Spread", Color(hex: "#f472b6")),
    "total":  ("O/U",    Color(hex: "#a3e635")),
    "nrfi":   ("NRFI",   Color(hex: "#67e8f9")),
    "f5ml":   ("F5 ML",  .brandAmber),
    "f5spread":("F5 RL", Color(hex: "#f472b6")),
]
```

---

## Files to Copy from `ai-agent-mlb` Repo

| File | Why |
|------|-----|
| `PROP_SCOUT_API.md` | Full API reference with all endpoint shapes |
| `prop-scout-handoff.md` | Full project context and architecture history |

Optional for reference only (do not import):
| File | Why |
|------|-----|
| `src/board/index.js` | Board scoring logic — helpful for understanding candidate fields |
| `backend/routes/picks.js` | Pick schema + grading field reference |

---

## Phase 1 Build Order (MVP)

1. **Project setup** — Xcode project, folder structure, `Color+Brand.swift`
2. **Networking layer** — `APIClient`, `Endpoints`, `KeychainManager`
3. **Auth** — `LoginView` + `AuthViewModel`, JWT Keychain storage
4. **Slate** — `SlateViewModel` fetches `/api/slate-bundle`, `SlateView` renders game list with LIVE badges and live scores
5. **Board** — `BoardViewModel` fetches snapshot, `BoardView` with 5 tabs, card views, live score overlay on cards, `WhyModalView`
6. **Picks** — `PicksViewModel`, `PicksView` with date sections, `LogPickSheet`, grading engine port, `PATCH /api/picks/:id/grade`
7. **Tab bar** — `MainTabView` wiring Slate / Board / Picks / Settings
8. **Settings** — preferred book picker + sign out
9. **Polish** — Loading skeletons, error states, pull-to-refresh, empty states

---

## Notes for the New Chat

- The backend is already fully built and deployed — do not modify backend files
- All auth, picks, board, and live score endpoints are production-ready
- The shared board snapshot (`/api/board/snapshot`) is the primary data source for the Board tab — it's pre-scored server-side at 10 AM HI daily. No client-side scoring needed.
- Pick grading happens client-side (port `gradePickLocally` logic to Swift) then persists via `PATCH /api/picks/:id/grade`
- The web app's `liveBoxscores` state is just a dictionary of boxscore responses keyed by gamePk — replicate this as `[Int: Boxscore]` in Swift
- Feature freeze on web app — only bug fixes. iOS is a greenfield new client.
