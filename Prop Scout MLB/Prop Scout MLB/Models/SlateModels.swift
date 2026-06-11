import Foundation

// MARK: - Slate Bundle
struct SlateBundle: Decodable {
    let schedule: [SlateGame]
    let oddsMap: [String: OddsData?]
    let nrfiMap: [String: NRFIData?]
    let weatherMap: [String: WeatherData?]
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

    var isDome: Bool { temp == nil }
    var relativehumidity: Double? { nil } // returned separately by weather API

    var tempString: String {
        guard let t = temp else { return "DOME" }
        return "\(Int(t))°"
    }

    var windLabel: String {
        guard let speed = windspeed, let dir = winddirection else { return "" }
        return "\(Int(speed)) mph \(compassLabel(for: dir))"
    }

    private func compassLabel(for degrees: Double) -> String {
        let dirs = ["N","NNE","NE","ENE","E","ESE","SE","SSE","S","SSW","SW","WSW","W","WNW","NW","NNW"]
        let index = Int((degrees / 22.5).rounded()) % 16
        return dirs[max(0, min(15, index))]
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
}
