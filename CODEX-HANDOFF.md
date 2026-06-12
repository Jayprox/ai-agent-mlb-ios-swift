# Prop Scout MLB — Codex Task Handoff

> **Latest review session:** Board HR/Hits empty tabs — fixed (backend + iOS decode).  
> Read **`COWORK-CODEX-REVIEW-HANDOFF.md`** first before touching Board code.

## Project context

iOS app in Swift/SwiftUI (MVP + Phase 2 in progress). Backend is a live Railway
deployment — iOS is a read/write client. Architecture: MVVM, `URLSession` +
`async/await`, no third-party dependencies. Min iOS 16.

**Repo:** `ai-agent-mlb-ios-swift`  
**Source root:** `Prop Scout MLB/Prop Scout MLB/`

All brand colors are defined in `Extensions/Color+Brand.swift` as `Color` static
extensions (`.brandBackground`, `.brandSurface`, `.brandGreen`, `.brandRed`,
`.brandAmber`, `.brandCyan`, `.brandPurple`, `.brandTextMuted`, `.brandTextDim`,
`.brandBorder`, `.brandBorder2`, `.brandText`). **Use these everywhere — no
hardcoded hex values.**

---

## Task 1 — Pick auto-grading engine

### File to create
`Prop Scout MLB/Prop Scout MLB/Services/PickGradingEngine.swift`

### What it does
After a game goes final, the app fetches the boxscore and grades each pending
pick. The result is written back to the server via `PATCH /api/picks/:id/grade`.

### Existing types (already compiled — do not redefine)

```swift
// Models/PickModels.swift
struct Pick: Decodable, Identifiable {
    let id: String
    let playerId: String?
    let playerName: String?
    let market: String          // "hr","hits","k","outs","ml","spread","total","nrfi","f5ml","f5spread"
    let side: String?           // "OVER","UNDER","HOME","AWAY","NRFI","YRFI"
    let bookLine: Double?
    let slateDate: String
    let gameLabel: String?
    let resultHit: Bool?
    let gradeStatus: String?
    var isPending: Bool         // resultHit == nil && gradeStatus == nil && voided != true
}

struct GradePickRequest: Encodable {
    let resultHit: Bool?
    let actualStat: Double?
    let gradeStatus: String?    // "ppd","scratch","push", or nil
}

struct Boxscore: Decodable {
    let gamePk: Int?
    let status: String?
    let isFinal: Bool?
    let away: BoxscoreTeam?
    let home: BoxscoreTeam?

    struct BoxscoreTeam: Decodable {
        let batters: [BoxscoreBatter]?
        let pitchers: [BoxscorePitcher]?
    }
    struct BoxscoreBatter: Decodable {
        let id: IntOrString?
        let name: String?
        let ab: Int?
        let h: Int?
        let hr: Int?
    }
    struct BoxscorePitcher: Decodable {
        let id: IntOrString?
        let name: String?
        let k: Int?
        let ip: String?
    }
}

// Network/APIClient.swift — already implemented
// APIClient.shared.get<T>(path:) async throws -> T
// APIClient.shared.patch<T,B>(path:body:) async throws -> T

// Network/Endpoints.swift
// Endpoints.linescore(gamePk: Int) -> String
// Endpoints.boxscore(gamePk: Int)  -> String
// Endpoints.pickGrade(id: String)  -> String

// Models/SlateModels.swift
struct LinescoreData: Decodable {
    let gamePk: Int
    let inning: Int
    let halfInning: String
    let awayScore: Int
    let homeScore: Int
    let outs: Int?
    var isTop: Bool { halfInning == "top" }
}
```

### Grading logic to port

Port this JavaScript logic to Swift. The gamePk is derived from `pick.playerId`
for game picks (ml/spread/total/nrfi/f5ml/f5spread) since `playerId` stores the
gamePk as a String for those markets. For prop picks (k/outs/hr/hits),
`pick.playerId` is the MLB player ID.

```js
// JavaScript reference — port this to Swift
function gradePickLocally(pick, boxscores, linescores) {
  const isGameMarket = ['ml','spread','total','nrfi','f5ml','f5spread']
    .includes(pick.market);

  if (isGameMarket) {
    // playerId holds the gamePk for game picks
    const gamePk = parseInt(pick.playerId);
    const ls = linescores[gamePk];
    if (!ls) return null; // not ready

    const awayScore = ls.awayScore ?? ls.away?.runs ?? 0;
    const homeScore = ls.homeScore ?? ls.home?.runs ?? 0;

    switch (pick.market) {
      case 'ml': {
        const awayWon = awayScore > homeScore;
        const hit = pick.side === 'AWAY' ? awayWon : !awayWon;
        return { resultHit: hit, actualStat: hit ? 1 : 0, gradeStatus: null };
      }
      case 'spread': {
        // side is team abbr (HOME/AWAY lean); bookLine is the spread
        const line = pick.bookLine ?? 1.5;
        const diff = (pick.side === 'AWAY')
          ? awayScore - homeScore
          : homeScore - awayScore;
        if (diff + line === 0) return { resultHit: null, actualStat: diff, gradeStatus: 'push' };
        return { resultHit: diff + line > 0, actualStat: diff, gradeStatus: null };
      }
      case 'total': {
        const total = awayScore + homeScore;
        const line = pick.bookLine ?? 8.5;
        if (total === line) return { resultHit: null, actualStat: total, gradeStatus: 'push' };
        const hit = pick.side === 'OVER' ? total > line : total < line;
        return { resultHit: hit, actualStat: total, gradeStatus: null };
      }
      case 'nrfi': {
        const innings = ls.innings ?? [];
        const firstInning = innings.find(i => i.num === 1);
        if (!firstInning) return null;
        const scored = (firstInning.away ?? 0) + (firstInning.home ?? 0);
        const hit = pick.side === 'NRFI' ? scored === 0 : scored > 0;
        return { resultHit: hit, actualStat: scored, gradeStatus: null };
      }
      case 'f5ml': {
        const innings = ls.innings ?? [];
        const f5 = innings.filter(i => i.num <= 5);
        if (f5.length < 5) return null; // not enough innings
        const awayF5 = f5.reduce((s,i) => s + (i.away ?? 0), 0);
        const homeF5 = f5.reduce((s,i) => s + (i.home ?? 0), 0);
        if (awayF5 === homeF5) return { resultHit: null, actualStat: null, gradeStatus: 'push' };
        const awayWon = awayF5 > homeF5;
        return { resultHit: pick.side === 'AWAY' ? awayWon : !awayWon,
                 actualStat: null, gradeStatus: null };
      }
      case 'f5spread': {
        const innings = ls.innings ?? [];
        const f5 = innings.filter(i => i.num <= 5);
        if (f5.length < 5) return null;
        const awayF5 = f5.reduce((s,i) => s + (i.away ?? 0), 0);
        const homeF5 = f5.reduce((s,i) => s + (i.home ?? 0), 0);
        const line = pick.bookLine ?? 1.5;
        const diff = pick.side === 'AWAY' ? awayF5 - homeF5 : homeF5 - awayF5;
        if (diff + line === 0) return { resultHit: null, actualStat: diff, gradeStatus: 'push' };
        return { resultHit: diff + line > 0, actualStat: diff, gradeStatus: null };
      }
    }
  }

  // Prop pick — use boxscore
  const gamePkForProp = deriveGamePkFromLabel(pick.gameLabel); // not needed in Swift
  // In Swift: iterate all boxscores to find the player by playerId

  // Find player across all boxscores
  for (const [gpk, bs] of Object.entries(boxscores)) {
    if (!bs?.isFinal) continue;
    const allBatters  = [...(bs.away?.batters  ?? []), ...(bs.home?.batters  ?? [])];
    const allPitchers = [...(bs.away?.pitchers ?? []), ...(bs.home?.pitchers ?? [])];

    switch (pick.market) {
      case 'hr': {
        const batter = allBatters.find(b => String(b.id) === pick.playerId);
        if (!batter) continue; // try next boxscore
        if (batter.ab === 0) return { resultHit: null, actualStat: null, gradeStatus: 'scratch' };
        const hr = batter.hr ?? 0;
        const line = pick.bookLine ?? 0.5;
        const hit = pick.side === 'OVER' ? hr > line : hr < line;
        return { resultHit: hr === line ? null : hit,
                 actualStat: hr,
                 gradeStatus: hr === line ? 'push' : null };
      }
      case 'hits': {
        const batter = allBatters.find(b => String(b.id) === pick.playerId);
        if (!batter) continue;
        if (batter.ab === 0) return { resultHit: null, actualStat: null, gradeStatus: 'scratch' };
        const hits = batter.h ?? 0;
        const line = pick.bookLine ?? 0.5;
        const hit = pick.side === 'OVER' ? hits > line : hits < line;
        return { resultHit: hits === line ? null : hit,
                 actualStat: hits,
                 gradeStatus: hits === line ? 'push' : null };
      }
      case 'k': {
        const pitcher = allPitchers.find(p => String(p.id) === pick.playerId);
        if (!pitcher) continue;
        const k = pitcher.k ?? 0;
        const line = pick.bookLine ?? 4.5;
        const hit = pick.side === 'OVER' ? k > line : k < line;
        return { resultHit: k === line ? null : hit,
                 actualStat: k,
                 gradeStatus: k === line ? 'push' : null };
      }
      case 'outs': {
        const pitcher = allPitchers.find(p => String(p.id) === pick.playerId);
        if (!pitcher) continue;
        // Convert "6.1" IP string to outs: 6*3 + 1 = 19
        const ipStr = pitcher.ip ?? '0.0';
        const parts = ipStr.split('.');
        const outs = parseInt(parts[0]) * 3 + parseInt(parts[1] ?? '0');
        const line = pick.bookLine ?? 17.5;
        const hit = pick.side === 'OVER' ? outs > line : outs < line;
        return { resultHit: outs === line ? null : hit,
                 actualStat: outs,
                 gradeStatus: outs === line ? 'push' : null };
      }
    }
  }
  return null; // player not found in any boxscore
}
```

### Swift implementation spec

Create `enum PickGradingEngine` with one static method:

```swift
static func grade(
    pick: Pick,
    boxscores: [Int: Boxscore],      // keyed by gamePk
    linescores: [Int: LinescoreData] // keyed by gamePk
) -> GradePickRequest?               // nil = not ready to grade
```

And a helper to convert IP string to outs:
```swift
static func ipToOuts(_ ip: String) -> Int
// "6.1" -> 19, "7.0" -> 21, "5.2" -> 17
```

For game picks: `pick.playerId` contains the gamePk as a String — parse it with
`Int(pick.playerId ?? "")`.

For prop picks: search all boxscores (only `isFinal == true`) for the player
whose `id` (as String) matches `pick.playerId`.

The `IntOrString` type used in `BoxscoreBatter.id` and `BoxscorePitcher.id`
already has a `stringValue: String` computed property — use that for comparison.
If `IntOrString` doesn't have `stringValue`, add it:
```swift
var stringValue: String {
    switch self { case .int(let i): return String(i); case .string(let s): return s }
}
```

### Where it gets called

In `PicksViewModel.swift`, add a method:

```swift
func gradeAllPending(boxscores: [Int: Boxscore], linescores: [Int: LinescoreData]) async {
    let pending = picks.filter { $0.isPending }
    for pick in pending {
        if let req = PickGradingEngine.grade(pick: pick, boxscores: boxscores, linescores: linescores) {
            _ = try? await APIClient.shared.patch(path: Endpoints.pickGrade(id: pick.id), body: req)
        }
    }
    await load() // refresh picks after grading
}
```

---

## Task 2 — Log Pick pre-fill from AI Board

### File to modify
`Prop Scout MLB/Prop Scout MLB/Views/Board/AIBoardEdgeCardView.swift`

### What to do

Identical pattern to `BoardCandidateCardView`. Add:

1. `@EnvironmentObject var picksVM: PicksViewModel` property
2. `@State private var showLogPick = false` state var
3. A `+` circle button (green `plus.circle.fill` SF Symbol, size 20) in the
   bottom row next to any existing buttons — triggers `showLogPick = true` with
   `HapticManager.light()`
4. A `.sheet(isPresented: $showLogPick)` presenting `LogPickSheet`
5. A computed `var edgePrefill: LogPickPrefill` built from the edge:

```swift
LogPickPrefill(
    playerName: edge.displayName,
    market: edge.market ?? "",
    side: edge.lean ?? "OVER",
    bookLine: edge.bookLine,
    odds: nil,
    gameLabel: edge.displayGameLabel
)
```

`LogPickPrefill` is already defined in `Views/Picks/LogPickSheet.swift`.  
`PicksViewModel` is already defined in `ViewModels/PicksViewModel.swift`.  
`HapticManager` is in `Extensions/HapticManager.swift`.

Also add `.environmentObject(picksVM)` in `AIBoardView.swift` where
`AIBoardEdgeCardView` is instantiated — `AIBoardView` should also declare
`@EnvironmentObject var picksVM: PicksViewModel`.

Then in `MainTabView.swift`, add `.environmentObject(picksVM)` to `AIBoardView()`:
```swift
AIBoardView()
    .environmentObject(picksVM)
    .tabItem { ... }
```

---

## Task 3 — Shimmer loading skeleton

### File to create
`Prop Scout MLB/Prop Scout MLB/Extensions/View+Shimmer.swift`

### Spec

A SwiftUI `ViewModifier` that overlays an animated shimmer (moving highlight from
left to right) on any view. Used to show loading placeholders.

```swift
// Usage:
RoundedRectangle(cornerRadius: 8)
    .fill(Color.brandSurface)
    .frame(height: 16)
    .shimmering()
```

Implementation requirements:
- Animate a linear gradient from `Color.brandSurface` → `Color.brandBorder2` →
  `Color.brandSurface` sweeping left-to-right, repeating forever
- The animation should use `.easeInOut(duration: 1.2).repeatForever(autoreverses: false)`
- Expose as a `.shimmering(active: Bool = true)` View extension
- When `active` is false, return the view unmodified (pass-through)
- Use `@State private var phase: CGFloat = -1` animating to `1` via
  `onAppear` + `withAnimation`

### Where it gets used (optional — Codex does not need to add these)

After creating the modifier, it will be used in Slate/Board/Picks loading states
to replace spinners with skeleton cards. The integration is a separate task.

---

## General rules for all tasks

- **No third-party imports** — Foundation, SwiftUI, Combine only
- **Use existing brand colors** — never hardcode hex
- **Use `DispatchQueue.main.async { }` for all @Published property updates**
  from async contexts (project uses this pattern, not `@MainActor`)
- **All network calls via `APIClient.shared`** — already handles auth headers
- **Do not modify** `APIClient.swift`, `KeychainManager.swift`,
  `Color+Brand.swift`, or any model file unless explicitly instructed
- Match the monospaced font style used everywhere:
  `.font(.system(size: N, weight: .bold, design: .monospaced))`
