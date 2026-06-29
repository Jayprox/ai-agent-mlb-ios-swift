import Foundation
import SwiftUI

// MARK: - Pitcher stats
struct PitcherStats: Decodable {
    let id: Int?
    let name: String?
    let team: String?
    let era: String?
    let whip: String?
    let kPer9: String?
    let bbPer9: String?
    let wins: Int?
    let losses: Int?
    let ip: String?
    let k: Int?
    let bb: Int?
}

// MARK: - Pitcher gamelog
struct PitcherGamelog: Decodable {
    let group: String?
    let seasonEra: String?
    let avgIP: String?
    let games: [PitcherGameEntry]?
}

struct PitcherGameEntry: Decodable, Identifiable {
    var id: String { "\(date ?? "")-\(opponent ?? "")" }
    let date: String?
    let opponent: String?
    let ip: String?
    let k: Int?
    let er: Int?
    let pc: Int?
    let result: String?
}

// MARK: - Pitcher splits (vs L/R + Home/Away + Day/Night)
struct PitcherSplits: Decodable {
    let pitcherId: Int?
    let season: Int?

    // Platoon splits
    let vsLeft: SplitLine?
    let vsRight: SplitLine?

    // Game site splits
    let home: GameSiteSplits?
    let away: GameSiteSplits?

    // Time of day splits
    let dayGame: GameSiteSplits?
    let nightGame: GameSiteSplits?

    struct SplitLine: Decodable {
        let avg: String?      // Batting average against
        let ops: String?      // Opponent OPS
        let k9: String?       // Strikeouts per 9 innings
        let bb9: String?      // Walks per 9 innings
    }

    struct GameSiteSplits: Decodable {
        let era: String?      // Earned run average
        let whip: String?     // Walks + hits per IP
        let ip: String?       // Innings pitched (sample size)
        let k9: String?       // Strikeouts per 9 innings
        let bb9: String?      // Walks per 9 innings
    }

    enum CodingKeys: String, CodingKey {
        case pitcherId, season
        case vsLeft = "vsL"    // Backend uses vsL as alias
        case vsRight = "vsR"   // Backend uses vsR as alias
        case home, away, dayGame, nightGame
    }
}

// MARK: - Lineup
// MARK: - Injuries
struct InjuriesData: Decodable {
    let injuries: [InjuryRecord]
}

struct InjuryRecord: Decodable {
    let playerId: Int?
    let playerName: String?
    let team: String?
    let status: String?
    let date: String?
    let description: String?
}

struct LineupData: Decodable {
    let gamePk: Int?
    let confirmed: Bool?
    let away: [LineupBatter]?
    let home: [LineupBatter]?
}

struct LineupBatter: Decodable, Identifiable {
    var id: Int { self.id2 ?? 0 }
    private let id2: Int?
    let name: String?
    let order: Int?
    let position: String?
    let batSide: String?
    let avg: String?
    let matchupScore: Double?
    let recentForm: RecentForm?

    enum CodingKeys: String, CodingKey {
        case id2 = "id"
        case name, order, position, batSide, avg, matchupScore, recentForm
    }
}

struct RecentForm: Decodable {
    let hotStreak: Bool?
    let coldStreak: Bool?
    let hrLast15: Int?
    let hrPer15AB: Double?
    let last15Games: Int?
}

// MARK: - Advanced Pitcher Stats
struct PitcherAdvancedStats: Decodable {
    let swStrPct: Double?        // Swinging strike %
    let oSwingPct: Double?       // Chase % (outside swing %)
    let fStrikePct: Double?      // First strike %
    let barrelPct: Double?       // Barrel %
    let xwOBAAllowed: Double?    // Expected wOBA
}

// MARK: - Arsenal (Savant pitch mix)
struct ArsenalData: Decodable {
    let pitcherId: Int?
    let season: Int?
    let pitcherStats: PitcherAdvancedStats?
    let arsenal: [PitchInfo]?
}

/// Flexible key for multi-name decoding (tries camelCase + snake_case + Savant aliases)
private struct FlexKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// Shared flexible decode helpers (multi-key lookup + bidirectional type coercion)
private enum FlexDecode {
    static func double(from c: KeyedDecodingContainer<FlexKey>, keys: String...) -> Double? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(Double.self, forKey: fk) { return v }
            if let s = try? c.decodeIfPresent(String.self, forKey: fk),
               let v = Double(s.replacingOccurrences(of: "%", with: "")
                               .trimmingCharacters(in: .whitespaces)) { return v }
        }
        return nil
    }

    static func int(from c: KeyedDecodingContainer<FlexKey>, keys: String...) -> Int? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(Int.self, forKey: fk) { return v }
            if let v = try? c.decodeIfPresent(Double.self, forKey: fk) { return Int(v) }
            if let s = try? c.decodeIfPresent(String.self, forKey: fk),
               let v = Int(s.trimmingCharacters(in: .whitespaces)) { return v }
        }
        return nil
    }

    static func string(from c: KeyedDecodingContainer<FlexKey>, keys: String...) -> String? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(String.self, forKey: fk), !v.isEmpty { return v }
            if let v = try? c.decodeIfPresent(Double.self, forKey: fk) {
                return v.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(v))" : String(format: "%.3f", v)
            }
        }
        return nil
    }

    /// Decode a nested object trying multiple possible keys.
    static func object<T: Decodable>(from c: KeyedDecodingContainer<FlexKey>, keys: String...) -> T? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(T.self, forKey: fk) { return v }
        }
        return nil
    }
}

struct PitchInfo: Decodable, Identifiable {
    var id: String { abbr ?? name ?? UUID().uuidString }

    let abbr: String?        // "FF", "SI", etc.         → API key: "abbr"
    let name: String?        // "4-Seam Fastball"        → API key: "type"
    let usagePct: Double?    // e.g. 42                  → API key: "pct"
    let avgVelo: Double?     // e.g. 93.1                → API key: "velo" (String in API)
    let whiffRate: Double?   // e.g. 19                  → API key: "whiffPct" (Int in API)
    let avg: String?         // batter avg               → API key: "ba"
    let slg: String?         // batter slg               → API key: "slg"
    let putAwayRate: Double? // put-away %               → API key: "putAwayPct" (if present)
    let prevVelo: Double?    // prior season avg velo    → API key: "prevVelo"
    let insight: String?     // matchup note             → API key: "insight" (if present)
    let warning: String?     // risk / usage alert       → API key: "warning" (if present)

    /// YoY velocity change — positive means gained velo, negative means lost
    var veloDelta: Double? {
        guard let cur = avgVelo, let prev = prevVelo else { return nil }
        return cur - prev
    }

    // MARK: - Static pitch name lookup (Statcast abbreviation → full name)
    static let pitchNameMap: [String: String] = [
        "FF": "4-Seam Fastball", "FA": "4-Seam Fastball",
        "FT": "2-Seam Fastball", "SI": "Sinker",
        "FC": "Cutter",
        "SL": "Slider",  "ST": "Sweeper",  "SW": "Sweeper",
        "CU": "Curveball", "KC": "Knuckle Curve", "CS": "Slow Curve",
        "CH": "Changeup", "FS": "Splitter", "FO": "Forkball",
        "KN": "Knuckleball", "EP": "Eephus", "SC": "Screwball",
        "SV": "Slurve",  "GY": "Gyroball"
    ]

    /// Full name from API or lookup table fallback
    var displayName: String {
        if let n = name, !n.isEmpty { return n }
        return Self.pitchNameMap[abbr ?? ""] ?? abbr ?? "—"
    }

    // MARK: - Flexible decoders (handle String↔Double API type ambiguity)

    /// Decode a Double — tries native Double first, then String→Double conversion
    private static func flexDouble(
        from c: KeyedDecodingContainer<FlexKey>,
        keys: String...
    ) -> Double? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(Double.self, forKey: fk) { return v }
            if let s = try? c.decodeIfPresent(String.self, forKey: fk),
               let v = Double(s.replacingOccurrences(of: "%", with: "")
                               .trimmingCharacters(in: .whitespaces)) { return v }
        }
        return nil
    }

    /// Decode a String — tries native String first, then formats a Double/Int as String
    private static func flexString(
        from c: KeyedDecodingContainer<FlexKey>,
        keys: String...
    ) -> String? {
        for k in keys {
            let fk = FlexKey(stringValue: k)
            if let v = try? c.decodeIfPresent(String.self, forKey: fk), !v.isEmpty { return v }
            if let v = try? c.decodeIfPresent(Double.self, forKey: fk) {
                return v.truncatingRemainder(dividingBy: 1) == 0
                    ? "\(Int(v))" : String(format: "%.3f", v)
            }
        }
        return nil
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlexKey.self)

        // Exact API keys first, then common fallbacks
        abbr = Self.flexString(from: c,
            keys: "abbr", "pitch_type", "pitchType")

        name = Self.flexString(from: c,
            keys: "type",                              // confirmed API key
                  "pitchName", "pitch_name", "name", "typeName", "pitchTypeName")

        usagePct = Self.flexDouble(from: c,
            keys: "pct",                               // confirmed API key
                  "usagePct", "usage_pct", "usage")

        avgVelo = Self.flexDouble(from: c,
            keys: "velo",                              // confirmed API key (String in API)
                  "avgVelo", "avg_velo", "avgSpeed", "velocity")

        whiffRate = Self.flexDouble(from: c,
            keys: "whiffPct",                          // confirmed API key (Int in API)
                  "whiffRate", "whiff_rate", "whiff_pct", "whiff")

        avg = Self.flexString(from: c,
            keys: "ba",                                // confirmed API key
                  "avg", "batter_avg", "batterAvg")

        slg = Self.flexString(from: c,
            keys: "slg")                               // confirmed API key

        putAwayRate = Self.flexDouble(from: c,
            keys: "putAwayPct", "putAwayRate", "put_away_rate", "put_away_pct")

        prevVelo = Self.flexDouble(from: c,
            keys: "prevVelo",                          // confirmed API key (Double in API)
                  "prev_velo", "prevAvgSpeed", "lastYearVelo")

        insight = Self.flexString(from: c,
            keys: "insight", "matchupNote", "matchup_note", "lineupNote", "note")

        warning = Self.flexString(from: c,
            keys: "warning", "riskNote", "risk_note", "heavyUsageAlert", "alert")
    }

    // Classify pitch quality for lineup matchup
    var quality: PitchQuality {
        guard let w = whiffRate else { return .neutral }
        if w >= 30 { return .weakSpot }
        if w <= 15 { return .handles }
        return .neutral
    }
}

enum PitchQuality {
    case weakSpot, handles, neutral

    var label: String {
        switch self {
        case .weakSpot: return "WEAK SPOT"
        case .handles:  return "HANDLES"
        case .neutral:  return "NEUTRAL"
        }
    }
}

// MARK: - Umpire
struct UmpireData: Decodable {
    let gamePk: Int?
    let homePlate: HomePlateUmpire?

    struct HomePlateUmpire: Decodable {
        let id: Int?
        let name: String?
        let stats: UmpireStats?
    }

    struct UmpireStats: Decodable {
        // Basic stats
        let kRate: String?
        let bbRate: String?
        let tendency: String?
        let rating: String?

        // Enhanced metrics
        let accuracy: String?           // e.g. "94.4%"
        let vsExp: String?              // e.g. "+1.37%"
        let consistency: String?        // e.g. "95.5%"
        let favorPerGame: String?       // e.g. "0.60"

        // Status badges
        let scorecardLive: Bool?
        let scoreStatus: String?        // "ACCURATE" | "BIASED" | "NEUTRAL"

        // Current game status
        let gameStatus: String?         // "Awaiting assignment" | "Active" | etc.

        // Season stats
        let season: Int?
        let gamesWorked: Int?
        let totalCalls: Int?

        enum CodingKeys: String, CodingKey {
            case kRate, bbRate, tendency, rating
            case accuracy, vsExp, consistency, favorPerGame
            case scorecardLive, scoreStatus, gameStatus
            case season, gamesWorked, totalCalls
        }
    }
}

// MARK: - NRFI detail
struct NRFIDetail: Decodable {
    let gamePk: Int?
    let away: NRFITeamData?
    let home: NRFITeamData?
    let lean: String?
    let confidence: Int?

    struct NRFITeamData: Decodable {
        let scoredPct: Double?
        let avgRuns: Double?
        let tendency: String?
    }
}

// MARK: - H2H career stats
struct H2HStats: Decodable {
    let atBats: Int
    let hits: Int?
    let avg: String?
    let homeRuns: Int?
    let strikeOuts: Int?
    let obp: String?
    let slg: String?
}

// MARK: - Batter hitting stats (for expanded row)
struct BatterHittingStats: Decodable {
    let avg: String?
    let ops: String?
    let hr: Int?
    let rbi: Int?
    // API also returns these but we decode leniently
    let name: String?
    let team: String?
}

// MARK: - Batter splits line (shared shape for /api/splits and /api/stat-splits)
struct StatSplitLine: Decodable {
    let avg: String?
    let obp: String?
    let slg: String?
    let ops: String?
    let hr: Int?
    let rbi: Int?
    let ab: Int?
    let whiffPct: Double?
    let hardHitPct: Double?
    let kRate: Double?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlexKey.self)
        avg = FlexDecode.string(from: c, keys: "avg", "battingAvg", "batting_avg")
        obp = FlexDecode.string(from: c, keys: "obp")
        slg = FlexDecode.string(from: c, keys: "slg")
        ops = FlexDecode.string(from: c, keys: "ops")
        hr  = FlexDecode.int(from: c, keys: "hr", "homeRuns", "home_runs")
        rbi = FlexDecode.int(from: c, keys: "rbi")
        ab  = FlexDecode.int(from: c, keys: "ab", "atBats", "at_bats")
        whiffPct = FlexDecode.double(from: c, keys: "whiffPct", "whiff_pct", "whiffRate")
        hardHitPct = FlexDecode.double(from: c, keys: "hardHitPct", "hard_hit_pct", "hardHitRate")
        kRate = FlexDecode.double(from: c, keys: "kRate", "k_rate", "strikeoutRate")
    }
}

// MARK: - Batter splits (/api/splits/:batterId and /api/stat-splits/:batterId?group=hitting)
struct BatterSplits: Decodable {
    let home: StatSplitLine?
    let away: StatSplitLine?
    let vsLeft: StatSplitLine?
    let vsRight: StatSplitLine?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlexKey.self)
        home = FlexDecode.object(from: c, keys: "home", "homeSplit", "home_split")
        away = FlexDecode.object(from: c, keys: "away", "awaySplit", "away_split")
        vsLeft = FlexDecode.object(from: c, keys: "vsLeft", "vs_left", "vsLHP", "vs_lhp")
        vsRight = FlexDecode.object(from: c, keys: "vsRight", "vs_right", "vsRHP", "vs_rhp")
    }
}

// MARK: - Batter gamelog (last 5 games)
struct BatterGameEntry: Decodable, Identifiable {
    var id: String { "\(date ?? "")-\(opponent ?? "")" }
    let date: String?
    let opponent: String?
    let ab: Int?
    let h: Int?
    let hr: Int?
    let rbi: Int?
    let avg: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlexKey.self)
        date = FlexDecode.string(from: c, keys: "date", "gameDate", "game_date")
        opponent = FlexDecode.string(from: c, keys: "opponent", "opp")
        ab = FlexDecode.int(from: c, keys: "ab", "atBats", "at_bats")
        h  = FlexDecode.int(from: c, keys: "h", "hits")
        hr = FlexDecode.int(from: c, keys: "hr", "homeRuns", "home_runs")
        rbi = FlexDecode.int(from: c, keys: "rbi")
        avg = FlexDecode.string(from: c, keys: "avg")
    }
}

struct BatterGamelog: Decodable {
    let games: [BatterGameEntry]

    init(from decoder: Decoder) throws {
        if let c = try? decoder.container(keyedBy: FlexKey.self),
           let g: [BatterGameEntry] = FlexDecode.object(from: c, keys: "games", "log", "gamelog") {
            games = g
        } else if let arr = try? decoder.singleValueContainer().decode([BatterGameEntry].self) {
            games = arr
        } else {
            games = []
        }
    }
}

// MARK: - RBI opportunity context
struct RBIContext: Decodable {
    let avgRISP: String?
    let rispOpportunities: Int?
    let runnersOnRate: Double?
    let clutchRating: String?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: FlexKey.self)
        avgRISP = FlexDecode.string(from: c, keys: "risp", "avgRISP", "avg_risp", "avgWithRisp")
        rispOpportunities = FlexDecode.int(from: c, keys: "rispOpportunities", "risp_opportunities", "opportunities")
        runnersOnRate = FlexDecode.double(from: c, keys: "runnersOnRate", "runners_on_rate", "runnersOnBaseRate")
        clutchRating = FlexDecode.string(from: c, keys: "clutchRating", "clutch_rating", "clutch", "rating")
    }
}

// MARK: - Bullpen
struct BullpenData: Decodable {
    let gamePk: Int?
    let away: BullpenTeam?
    let home: BullpenTeam?

    struct BullpenTeam: Decodable {
        let grade: String?            // e.g. "C+", "B"
        let gradeColor: String?       // hex color, e.g. "#22c55e"
        let fatigueLevel: String?     // "MODERATE" | "HIGH" | "LOW"
        let restDays: Int?
        let pitchesLast3: Int?
        let setupDepth: String?       // e.g. "deep"
        let lrBalance: String?        // e.g. "rh heavy"
        let note: String?             // fatigue note
        let lean: String?             // insight line
        let relievers: [Reliever]?

        /// "deep depth · rh heavy"
        var depthSummary: String {
            var parts: [String] = []
            if let depth = setupDepth { parts.append("\(depth) depth") }
            if let lr = lrBalance { parts.append(lr) }
            return parts.joined(separator: " · ")
        }
    }

    struct Reliever: Decodable, Identifiable {
        var id: String { name ?? UUID().uuidString }
        let name: String?
        let hand: String?
        let era: String?
        let whip: String?
        let k9: String?
        let bb9: String?
        let role: String?      // "CL" | "SU" | "MR"
        let lastApp: String?
        let pitches: Int?
        let status: String?    // "FRESH" | "TIRED"
    }
}

// MARK: - AI Trend Summary
struct TrendsSummary: Decodable {
    let summary: String?
    let gameKey: String?
    let generatedAt: String?
}

// MARK: - Scout Notes
struct ScoutNoteResponse: Decodable {
    let notes: [ScoutNote]?
}

struct ScoutNote: Decodable, Identifiable {
    let id: String
    let note: String?
    let createdAt: String?
    let username: String?

    /// Formatted relative timestamp, e.g. "Jun 9"
    var displayDate: String {
        guard let raw = createdAt else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: raw) ?? ISO8601DateFormatter().date(from: raw) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Top Matchups
struct TopMatchupsResponse: Decodable {
    let gamePk: Int
    let matchups: [Matchup]
    let note: String?

    struct Matchup: Decodable, Identifiable {
        var id: String { "\(batter.id)-\(pitcher.id)" }

        let batter: Player
        let pitcher: Player
        let matchupScore: Double
        let trend: String?      // "up" | "down" | "neutral"
        let reason: String?

        struct Player: Decodable {
            let id: Int
            let name: String
            let position: String?   // only on batter
        }
    }
}

// MARK: - Arsenal vs Batter (pitch-by-pitch analysis)
struct ArsenalVsBatterResponse: Decodable {
    let pitcherId: Int
    let batterId: Int
    let season: Int
    let arsenal: [PitchCard]
    let pitcherStats: PitcherAdvancedStats?

    struct PitchCard: Decodable, Identifiable {
        var id: String { abbr }

        // Pitcher pitch info
        let abbr: String
        let type: String
        let pct: Int
        let velo: String?
        let whiffPct: Int?
        let color: String
        let prevVelo: String?

        // Batter vs pitch
        let batterAvg: String?
        let batterWhiff: String?
        let batterSlg: String?

        // Pre-computed labels
        let label: String              // "HANDLES" | "WEAK SPOT" | "NEUTRAL"
        let note: String?
        let riskNote: String?

        /// YoY velocity delta (positive = gained velo)
        var veloDelta: Double? {
            guard let cur = Double(velo ?? ""), let prev = Double(prevVelo ?? "") else { return nil }
            return cur - prev
        }

        /// Velocity delta badge string
        var velocityBadge: String? {
            guard let delta = veloDelta, abs(delta) >= 0.4 else { return nil }
            if delta >= 1.5 {
                return "▲ +\(String(format: "%.1f", delta)) mph YoY"
            } else if delta > 0 {
                return "▲ +\(String(format: "%.1f", delta)) mph YoY"
            } else if delta <= -1.5 {
                return "▼ \(String(format: "%.1f", delta)) mph YoY"
            } else {
                return "▼ \(String(format: "%.1f", delta)) mph YoY"
            }
        }

        var labelBackgroundColor: Color {
            switch label {
            case "HANDLES": return Color(red: 0.13, green: 0.78, blue: 0.35)       // green #22c55e
            case "WEAK SPOT": return Color(red: 0.94, green: 0.26, blue: 0.26)     // red #ef4444
            default: return Color(red: 0.96, green: 0.62, blue: 0.07)              // amber #f59e0b
            }
        }

        var velocityBadgeColor: Color {
            guard let delta = veloDelta else { return .gray }
            if delta >= 0.4 { return Color(red: 0.13, green: 0.78, blue: 0.35) }   // green
            if delta <= -1.5 { return Color(red: 0.94, green: 0.26, blue: 0.26) }  // red
            return Color(red: 0.96, green: 0.62, blue: 0.07)                       // amber
        }

        var pitchColorValue: Color {
            // color is hex string like "#38bdf8"
            Color(hex: color)
        }
    }
}

/// Used for POST responses that return an empty body or simple acknowledgement
struct EmptyOK: Decodable {}
