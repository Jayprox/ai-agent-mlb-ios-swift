import Foundation

// MARK: - Slate Bundle
struct SlateBundle: Decodable {
    let schedule: [SlateGame]
    let oddsMap: [String: OddsData?]?
    let nrfiMap: [String: NRFIData?]?
    let weatherMap: [String: WeatherData?]?
    let kHintsMap: [String: String?]?  // gamePk → "Wacha K OVER" hint string
    let fetchedAt: String?
}

// MARK: - Game
struct SlateGame: Decodable, Identifiable {
    let gamePk: Int
    let status: String
    let gameTime: String?
    let away: TeamInfo
    let home: TeamInfo
    let venue: String?
    let probablePitchers: ProbablePitchers?

    var id: Int { gamePk }

    // Key used to look up odds in oddsMap
    var oddsKey: String { "\(away.name)|\(home.name)" }

    // MARK: - Status helpers
    var isLive: Bool {
        ["Warmup", "In Progress"].contains(status)
    }
    var isFinal: Bool {
        ["Final", "Game Over", "Completed Early"].contains(status)
    }
    var isPPD: Bool {
        ["Postponed", "Cancelled", "Suspended"].contains(status)
    }
    var isUpcoming: Bool {
        !isLive && !isFinal && !isPPD
    }

    // Formatted local game time (e.g. "4:05 PM")
    var formattedTime: String {
        guard let gt = gameTime,
              let date = ISO8601DateFormatter().date(from: gt) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = .current
        return f.string(from: date)
    }

    // Inning display for live games (e.g. "▲6" or "▼9")
    func inningLabel(linescore: LinescoreData?) -> String {
        guard let ls = linescore else { return "" }
        return "\(ls.isTop ? "▲" : "▼")\(ls.inning)"
    }

    enum CodingKeys: String, CodingKey {
        case gamePk
        case status
        case gameTime
        case away
        case home
        case venue
        case stadium
        case ballpark
        case probablePitchers
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamePk = try c.decode(Int.self, forKey: .gamePk)
        status = try c.decode(String.self, forKey: .status)
        gameTime = try c.decodeIfPresent(String.self, forKey: .gameTime)
        away = try c.decode(TeamInfo.self, forKey: .away)
        home = try c.decode(TeamInfo.self, forKey: .home)
        probablePitchers = try c.decodeIfPresent(ProbablePitchers.self, forKey: .probablePitchers)
        venue =
            try c.decodeIfPresent(String.self, forKey: .venue) ??
            c.decodeIfPresent(String.self, forKey: .stadium) ??
            c.decodeIfPresent(String.self, forKey: .ballpark)
    }
}

struct TeamInfo: Decodable {
    let id: Int
    let name: String
    let abbr: String
}

struct ProbablePitchers: Decodable {
    let away: PitcherInfo?
    let home: PitcherInfo?
}

struct PitcherInfo: Decodable {
    let id: Int
    let name: String
    let hand: String?
    let isIL: Bool?  // true when pitcher is on the Injured List
}

// MARK: - Odds
struct OddsData: Decodable {
    let awayML: String?
    let homeML: String?
    let total: String?
    let overOdds: String?
    let underOdds: String?
    let awaySpread: String?
    let awaySpreadOdds: String?
    let homeSpread: String?
    let homeSpreadOdds: String?
    let book: String?
    let trend: String?  // "OVER" or "UNDER" — public money / line movement signal
}

// MARK: - NRFI
struct NRFIData: Decodable {
    let lean: String?
    let confidence: Int?
    let reason: String?  // e.g. "SF scored in 1st" — shown in badge when available
}

// MARK: - Weather
struct WeatherData: Decodable {
    let temp: Double?
    let windspeed: Double?
    let winddirection: Double?
    let weathercode: Int?
    let precipitation_probability: Double?
    let relativehumidity: Double?
    let isDome: Bool?  // Backend should provide this explicitly

    var tempString: String {
        guard let t = temp else { return "DOME" }
        return "\(Int(t))°"
    }

    var windLabel: String {
        guard let speed = windspeed, let dir = winddirection else { return "" }
        return "\(Int(speed)) mph \(fieldWindLabel(for: dir))"
    }

    /// Convert wind direction (degrees) to field-relative label
    /// 0° = N, 90° = E, 180° = S, 270° = W
    /// Baseball field: Home plate faces toward pitcher's mound in center
    /// Assume field orientation: LF=90°/East, CF=0°/North, RF=270°/West
    private func fieldWindLabel(for degrees: Double) -> String {
        // Normalize to 0-360
        let normalized = ((degrees.truncatingRemainder(dividingBy: 360)) + 360).truncatingRemainder(dividingBy: 360)

        // Determine field direction and whether wind is blowing OUT (away) or IN (toward)
        // OUT = wind is blowing toward the field (outfield)
        // IN = wind is blowing toward home plate (infield)

        switch normalized {
        case 0..<22.5, 337.5..<360:     // N: toward center field
            return "OUT to CF"
        case 22.5..<67.5:                // NE: toward right-center
            return "OUT to RF"
        case 67.5..<112.5:               // E: toward right field
            return "OUT to RF"
        case 112.5..<157.5:              // SE: toward right field/infield
            return "IN from RF"
        case 157.5..<202.5:              // S: toward home/infield
            return "IN"
        case 202.5..<247.5:              // SW: toward left field/infield
            return "IN from LF"
        case 247.5..<292.5:              // W: toward left field
            return "OUT to LF"
        case 292.5..<337.5:              // NW: toward left-center
            return "OUT to LF"
        default:
            return "OUT to CF"
        }
    }
}

// MARK: - Linescore
struct InningLine: Decodable {
    let num: Int
    let away: Int?
    let home: Int?
}

struct LinescoreData: Decodable {
    let gamePk: Int
    let inning: Int
    let halfInning: String   // "top" or "bottom"
    let awayScore: Int
    let homeScore: Int
    let outs: Int?
    let innings: [InningLine]?

    var isTop: Bool { halfInning == "top" }

    enum CodingKeys: String, CodingKey {
        case gamePk, inning, halfInning, awayScore, homeScore, outs, innings
    }

    /// Custom decode: for games that haven't started yet, the API returns
    /// `inning`/`halfInning`/`awayScore`/`homeScore` as `null` rather than
    /// `0`/omitted, which fails synthesized `Decodable` (`Int`/`String` can't
    /// hold `null`). Treat `null` the same as "not started" — inning 0,
    /// scores 0, half "top".
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamePk     = try c.decode(Int.self, forKey: .gamePk)
        inning     = (try? c.decode(Int.self, forKey: .inning)) ?? 0
        halfInning = (try? c.decode(String.self, forKey: .halfInning)) ?? "top"
        awayScore  = (try? c.decode(Int.self, forKey: .awayScore)) ?? 0
        homeScore  = (try? c.decode(Int.self, forKey: .homeScore)) ?? 0
        outs       = try? c.decode(Int.self, forKey: .outs)
        innings    = try? c.decode([InningLine].self, forKey: .innings)
    }
}
