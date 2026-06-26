import Foundation

// MARK: - Pick
struct Pick: Decodable, Identifiable {
    let id: String
    let playerId: String?
    let playerName: String?
    let market: String
    let side: String?
    let bookLine: Double?
    let odds: IntOrString?
    let units: Double?
    let slateDate: String
    let gameLabel: String?
    let resultHit: Bool?
    let actualStat: Double?
    let gradeStatus: String?
    let pnl: Double?
    let voided: Bool?

    // MARK: - Display helpers
    var isPending: Bool  { resultHit == nil && gradeStatus == nil && voided != true }
    var isVoided: Bool   { voided == true }
    var isHit: Bool      { resultHit == true && gradeStatus == nil }
    var isMiss: Bool     { resultHit == false && gradeStatus == nil }
    var isPPD: Bool      { gradeStatus == "ppd" }
    var isScratch: Bool  { gradeStatus == "scratch" }
    var isPush: Bool     { gradeStatus == "push" }

    var formattedDate: String {
        // slateDate may be "2026-06-07" or "2026-06-07T00:00:00.000Z"
        let raw = String(slateDate.prefix(10))
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let date = f.date(from: raw) else { return raw }
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    // Normalized date key for grouping (always "yyyy-MM-dd")
    var dateKey: String { String(slateDate.prefix(10)) }

    var oddsDisplay: String? {
        switch odds {
        case .int(let i):    return i >= 0 ? "+\(i)" : "\(i)"
        case .string(let s): return s
        case nil:            return nil
        }
    }

    var lineDisplay: String {
        var parts: [String] = []

        // Add side if present
        if let s = side {
            parts.append(displaySide)
        }

        // Add line if present
        if let line = bookLine {
            let lineStr = line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line)
            parts.append(lineStr)
        }

        // Always add market
        parts.append(market)

        return parts.joined(separator: " ")
    }

    private var displaySide: String {
        guard let side else { return "" }
        let normalized = side.uppercased()
        guard normalized == "HOME" || normalized == "AWAY",
              let gameLabel,
              let teams = parseTeams(from: gameLabel) else {
            return side
        }
        return normalized == "AWAY" ? teams.away : teams.home
    }

    private func parseTeams(from label: String) -> (away: String, home: String)? {
        let separators = [" @ ", " vs "]
        for separator in separators {
            let parts = label.components(separatedBy: separator)
            if parts.count == 2 {
                let away = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let home = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                if !away.isEmpty && !home.isEmpty {
                    return (away, home)
                }
            }
        }
        return nil
    }

    var pnlDisplay: String {
        guard let p = pnl else { return "" }
        return p >= 0 ? "+\(String(format: "%.2f", p))u" : "\(String(format: "%.2f", p))u"
    }

    var actualStatDisplay: String? {
        guard let actualStat else { return nil }

        let formattedValue: String = {
            if actualStat == actualStat.rounded() {
                return "\(Int(actualStat))"
            }
            return String(format: "%.1f", actualStat)
        }()

        switch market.lowercased() {
        case "k":
            return "\(formattedValue) K"
        case "outs":
            return "\(formattedValue) outs"
        case "hits":
            return "\(formattedValue) hits"
        case "hr":
            return "\(formattedValue) HR"
        default:
            return nil
        }
    }
}

// MARK: - API responses
struct PicksResponse: Decodable {
    let picks: [Pick]
}

struct PicksStats: Decodable {
    let wins: Int
    let losses: Int
    let pending: Int
    let hitRate: Double?
    let totalPnl: Double?

    var record: String { "\(wins)-\(losses)" }
    var hitRateDisplay: String {
        guard let hr = hitRate else { return "—" }
        // API may return decimal (0.8) or percentage (80.0) — normalize
        let pct = hr > 1 ? hr : hr * 100
        return "\(Int(pct.rounded()))%"
    }
    var pnlDisplay: String {
        guard let p = totalPnl else { return "—" }
        return p >= 0 ? "+\(String(format: "%.2f", p))u" : "\(String(format: "%.2f", p))u"
    }
}

// MARK: - Log pick request
struct LogPickRequest: Encodable {
    let playerId: Int?
    let playerName: String
    let market: String
    let side: String
    // Optional — the backend only requires playerId/market/side/slateDate and
    // stores bookLine as `null` when omitted (common for game-level markets
    // like NRFI/Total/Spread/ML where no line was available at compute time).
    let bookLine: Double?
    let odds: String?
    let units: Double
    let slateDate: String
    let gameLabel: String
    let source: String
}

// MARK: - Grade request
struct GradePickRequest: Encodable {
    let resultHit: Bool?
    let actualStat: Double?
    let gradeStatus: String?
}

// MARK: - Boxscore for grading
struct Boxscore: Decodable {
    let gamePk: Int?
    let isFinal: Bool?
    let linescore: BoxscoreLinescore?
    let batting: BoxscoreTeamStats?
    let pitching: BoxscoreTeamStats?

    /// True when 9+ innings are recorded (reliable finality signal)
    var isComplete: Bool { linescore?.innings?.count ?? 0 >= 9 }

    struct BoxscoreLinescore: Decodable {
        let innings: [InningLine]?
        let away: LineTotals?
        let home: LineTotals?

        struct LineTotals: Decodable {
            let runs: Int?
            let hits: Int?
            let errors: Int?
        }
    }

    struct BoxscoreTeamStats: Decodable {
        let away: [BoxscorePlayer]?
        let home: [BoxscorePlayer]?
    }

    struct BoxscorePlayer: Decodable {
        let id: IntOrString?
        let name: String?
        let pos: String?
        // Batting
        let ab: Int?
        let r: Int?
        let h: Int?
        let doubles: Int?
        let triples: Int?
        let hr: Int?
        let rbi: Int?
        let tb: Int?
        let bb: Int?
        let k: Int?
        let avg: String?
        // Pitching
        let ip: String?
        let er: Int?
        let pc: Int?
        let era: String?
    }
}
