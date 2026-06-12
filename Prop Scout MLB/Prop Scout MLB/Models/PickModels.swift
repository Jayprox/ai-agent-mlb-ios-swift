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
        guard let line = bookLine else { return "" }
        let lineStr = line == line.rounded() ? "\(Int(line))" : String(format: "%.1f", line)
        let sideStr = side ?? ""
        return "\(sideStr) \(lineStr)".trimmingCharacters(in: .whitespaces)
    }

    var pnlDisplay: String {
        guard let p = pnl else { return "" }
        return p >= 0 ? "+\(String(format: "%.2f", p))u" : "\(String(format: "%.2f", p))u"
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
