import Foundation

// MARK: - Boxscore response
struct GameBoxscore: Decodable {
    let gamePk: Int
    let isFinal: Bool
    let linescore: BoxscoreLinescore?
    let batting: BattingGroup?
    let pitching: PitchingGroup?

    enum CodingKeys: String, CodingKey {
        case gamePk, isFinal, linescore, batting, pitching
    }
}

// MARK: - Boxscore linescore with per-inning breakdown
struct BoxscoreLinescore: Decodable {
    let innings: [InningScore]
    let away: BoxscoreTeam?
    let home: BoxscoreTeam?
}

// MARK: - Per-inning score
struct InningScore: Decodable {
    let num: Int
    let away: Int?
    let home: Int?
}

// MARK: - Team stats in boxscore
struct BoxscoreTeam: Decodable {
    let runs: Int?
    let hits: Int?
    let errors: Int?
}

// MARK: - Batting group
struct BattingGroup: Decodable {
    let away: [BatterResult]?
    let home: [BatterResult]?
}

// MARK: - Pitcher group
struct PitchingGroup: Decodable {
    let away: [PitcherResult]?
    let home: [PitcherResult]?
}

// MARK: - Batter result
struct BatterResult: Decodable {
    let id: Int
    let name: String?
    let h: Int?      // hits
    let hr: Int?     // home runs
    let ab: Int?     // at bats
}

// MARK: - Pitcher result
struct PitcherResult: Decodable {
    let id: Int
    let name: String?
    let k: Int?      // strikeouts
    let ip: String?  // innings pitched (e.g. "6.0")
    let outs: Int?   // total outs pitched
}

// MARK: - Result cache entry
struct PlayerResult {
    let h: Int?
    let hr: Int?
    let ab: Int?
    let k: Int?
    let outs: Int?
    let live: Bool
}

// MARK: - Badge outcome
enum BadgeOutcome {
    case hit
    case miss
    case pending
}
