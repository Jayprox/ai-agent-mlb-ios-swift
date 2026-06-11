import Foundation
import SwiftUI

// MARK: - Flexible string/number value
/// The board API is inconsistent about whether "line" values are sent as
/// strings (e.g. ML "+138") or numbers (e.g. Total "8.5"). Decode either.
enum FlexibleValue: Decodable {
    case string(String)
    case double(Double)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let d = try? c.decode(Double.self) { self = .double(d); return }
        throw DecodingError.typeMismatch(
            FlexibleValue.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Expected String or Double")
        )
    }

    var stringValue: String {
        switch self {
        case .string(let s): return s
        case .double(let d): return d == d.rounded() ? "\(Int(d))" : String(format: "%.1f", d)
        }
    }
}

// MARK: - Lossy array
/// Decodes an array of `T`, silently skipping any elements that fail to
/// decode instead of failing the entire array (and, by extension, the whole
/// `BoardSnapshot`). This protects markets like K/Outs/Games from going
/// blank just because a single HR/Hits "LINEUP TBD" candidate has an
/// unexpected shape.
struct LossyArray<T: Decodable>: Decodable {
    let elements: [T]

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result: [T] = []
        while !container.isAtEnd {
            if let value = try? container.decode(T.self) {
                result.append(value)
            } else {
                // Skip the malformed element. `decode` advances the
                // container's cursor even when it throws, so this won't loop
                // forever — but guard with a generic decode just in case.
                _ = try? container.decode(EmptyDecodable.self)
            }
        }
        elements = result
    }
}

private struct EmptyDecodable: Decodable {}

// MARK: - Score signal (individual scoring component)
struct ScoreSignal: Decodable, Identifiable {
    var id: String { label }
    let label: String
    let earned: Double
    let max: Double
    let value: String?
    let description: String?

    var fillFraction: Double { max > 0 ? min(earned / max, 1.0) : 0 }
    var barColor: Color {
        let frac = fillFraction
        if frac >= 0.85 { return .brandGreen }
        if frac >= 0.5  { return .brandAmber }
        return .brandTextDim
    }
    var scoreLabel: String {
        let e = earned == earned.rounded() ? "\(Int(earned))" : String(format: "%.1f", earned)
        let m = max    == max.rounded()    ? "\(Int(max))"    : String(format: "%.1f", max)
        return earned >= 0 ? "+\(e) / \(m)" : "\(e) / \(m)"
    }
}

// MARK: - Prop line (nested in candidate)
struct PropLine: Decodable {
    let book: String?
    let line: Double?
    let overOdds: String?
    let underOdds: String?
    let marketLabel: String?
    let books: [String: BookOdds?]?

    struct BookOdds: Decodable {
        let line: Double?
        let overOdds: String?
        let underOdds: String?
    }
}

// MARK: - Game odds (game-market candidates: ML / Spread / Total / F5 ML / F5 RL)
/// Per-book odds lines, keyed by short book code ("DK", "FD", "CZR", "MGM").
struct BookLines: Decodable {
    let total: String?
    let awayML: String?
    let homeML: String?
    let overOdds: String?
    let underOdds: String?
    let awaySpread: String?
    let homeSpread: String?
    let awaySpreadOdds: String?
    let homeSpreadOdds: String?
    let f5Total: String?
    let f5AwayML: String?
    let f5HomeML: String?
    let f5AwaySpread: String?
    let f5HomeSpread: String?
    let f5AwaySpreadOdds: String?
    let f5HomeSpreadOdds: String?
}

/// Top-level per-game odds payload — same shape as `BookLines` plus the
/// "best book" code and a `books` dict of all available books.
struct GameOdds: Decodable {
    let book: String?
    let books: [String: BookLines]?
    let total: String?
    let awayML: String?
    let homeML: String?
    let overOdds: String?
    let underOdds: String?
    let awaySpread: String?
    let homeSpread: String?
    let awaySpreadOdds: String?
    let homeSpreadOdds: String?
    let f5Total: String?
    let f5AwayML: String?
    let f5HomeML: String?
    let f5AwaySpread: String?
    let f5HomeSpread: String?
    let f5AwaySpreadOdds: String?
    let f5HomeSpreadOdds: String?
}

// MARK: - Snapshot response
struct BoardSnapshot: Decodable {
    let hr: [BoardCandidate]?
    let hits: [BoardCandidate]?
    let k: [BoardCandidate]?
    let outs: [BoardCandidate]?
    let total: [BoardCandidate]?
    let ml: [BoardCandidate]?
    let spread: [BoardCandidate]?
    let nrfi: [BoardCandidate]?
    let f5ml: [BoardCandidate]?
    let f5spread: [BoardCandidate]?
    let generatedAt: String?
    let date: String?

    enum CodingKeys: String, CodingKey {
        case hr, hits, k, outs, total, ml, spread, nrfi, f5ml, f5spread, generatedAt, date
    }

    /// Custom decode: each market array is decoded leniently via
    /// `LossyArray` so a malformed candidate in one market (e.g. an HR/Hits
    /// "LINEUP TBD" roster candidate with an unexpected field shape) can't
    /// blank out the other markets — or the whole snapshot.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        hr          = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .hr)?.elements
        hits        = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .hits)?.elements
        k           = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .k)?.elements
        outs        = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .outs)?.elements
        total       = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .total)?.elements
        ml          = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .ml)?.elements
        spread      = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .spread)?.elements
        nrfi        = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .nrfi)?.elements
        f5ml        = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .f5ml)?.elements
        f5spread    = try c.decodeIfPresent(LossyArray<BoardCandidate>.self, forKey: .f5spread)?.elements
        generatedAt = try c.decodeIfPresent(String.self, forKey: .generatedAt)
        date        = try c.decodeIfPresent(String.self, forKey: .date)
    }

    func candidates(for market: BoardMarket) -> [BoardCandidate] {
        let raw: [BoardCandidate]
        switch market {
        case .hr:      raw = hr ?? []
        case .hits:    raw = hits ?? []
        case .k:       raw = k ?? []
        case .outs:    raw = outs ?? []
        case .nrfi:    raw = nrfi ?? []
        case .total:   raw = total ?? []
        case .ml:      raw = ml ?? []
        case .spread:  raw = spread ?? []
        case .f5ml:    raw = f5ml ?? []
        case .f5spread:raw = f5spread ?? []
        }
        // Inject market string into each candidate
        return raw.map { c in
            var copy = c; copy.market = market.rawValue; return copy
        }
    }

    /// Raw (un-injected) array for a market, preserving the missing-vs-empty
    /// distinction `candidates(for:)` collapses to `[]`. Used to detect the
    /// "checked, nothing qualifies yet" (`[]`) state for lineup-dependent
    /// markets like HR/Hits so the UI/view model can decide whether to poll
    /// for a live recompute.
    func rawArray(for market: BoardMarket) -> [BoardCandidate]? {
        switch market {
        case .hr:       return hr
        case .hits:     return hits
        case .k:        return k
        case .outs:     return outs
        case .nrfi:     return nrfi
        case .total:    return total
        case .ml:       return ml
        case .spread:   return spread
        case .f5ml:     return f5ml
        case .f5spread: return f5spread
        }
    }
}

// MARK: - API pre-computed factor (game markets: ml, spread, total, nrfi, f5ml, f5spread)
struct ApiWhyFactor: Decodable {
    let label: String
    let value: String?
    let detail: String?
    let pts: Int
    let max: Int
}

// MARK: - Weather (game markets — live conditions at the ballpark)
struct BoardWeather: Decodable {
    let temp: Int?
    let condition: String?
    let windspeed: Double?
    let hrFavorable: Bool?
    let weathercode: Int?
    let winddirection: Int?
    let relativehumidity: Int?
    let precipitationProbability: Int?

    enum CodingKeys: String, CodingKey {
        case temp, condition, windspeed, hrFavorable, weathercode, winddirection, relativehumidity
        case precipitationProbability = "precipitation_probability"
    }
}

// MARK: - Candidate
struct BoardCandidate: Decodable, Identifiable {
    let rawId: Int?        // player ID — absent on game-market picks
    let name: String?
    let team: String?
    let hand: String?
    let gamePk: Int?
    let gameLabel: String?

    // Stable Identifiable id from available fields
    var id: String { "\(rawId ?? 0)-\(gamePk ?? 0)-\(gameLabel ?? "")-\(market)" }
    let gameTime: String?
    let score: Int
    let simConfidence: Int?
    let propLine: PropLine?
    let signals: [String]?
    let suggestedLine: Double?
    let facingTeam: String?

    // Pitcher fields (strings from API)
    let era: String?
    let whip: String?
    let avgIP: String?
    let avgK3: String?
    let k9: String?

    // Batter fields
    let avg: String?
    let ops: String?
    let slg: String?
    let hitRate: [Int?]?
    let hrTotal: String?      // season HR count — JSON key "hr"
    let windFav: Bool?
    let order: Int?

    // Umpire
    let umpire: String?
    let umpireRating: String? // "pitcher" | "neutral" | "hitter" | nil

    // Game market fields
    let lean: String?
    let leanAbbr: String?
    let line: FlexibleValue? // e.g. "+138" (ML, string), -1.5 (Spread), 8.5 (Total, number)
    let odds: GameOdds?

    // Live weather + park factor (game markets)
    let weather: BoardWeather?
    let parkFactor: Double?

    // Result
    let resultHit: Bool?
    let gradeStatus: String?

    // AI summary
    let boardSummary: String?

    // Legacy API breakdown (kept for future use)
    let scoreBreakdown: [ScoreSignal]?

    // Pre-computed factors from API (game markets)
    let factors: [ApiWhyFactor]?

    // Injected after decode
    var market: String = ""

    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case name, team, hand, gamePk, gameLabel, gameTime, score
        case simConfidence, propLine, signals, suggestedLine, facingTeam
        case era, whip, avgIP, avgK3, k9
        case avg, ops, slg, hitRate
        case hrTotal = "hr"
        case windFav, order
        case umpire, umpireRating
        case lean, leanAbbr, line, odds
        case weather, parkFactor
        case resultHit, gradeStatus
        case boardSummary   = "_boardSummary"
        case scoreBreakdown = "_scoreBreakdown"
        case factors
    }

    // MARK: - Computed
    var bookLine: Double?  { propLine?.line }
    var overOdds: String?  { propLine?.overOdds }
    var underOdds: String? { propLine?.underOdds }
    var bestBook: String?  { propLine?.book }

    // MARK: - Game-market odds helpers
    var leanIsHome: Bool  { (lean ?? "").uppercased() == "HOME" }
    var leanIsUnder: Bool { (lean ?? "").uppercased() == "UNDER" }

    /// Numeric line shown for Spread/Total/F5 RL cards (nil for ML/F5 ML/NRFI,
    /// where the "line" IS the moneyline odds, shown via `gameDisplayOdds`).
    var gameDisplayLine: String? {
        switch market.lowercased() {
        case "total":    return odds?.total ?? line?.stringValue
        case "spread":   return (leanIsHome ? odds?.homeSpread   : odds?.awaySpread)   ?? line?.stringValue
        case "f5spread": return  leanIsHome ? odds?.f5HomeSpread : odds?.f5AwaySpread
        default: return nil
        }
    }

    /// Odds for the displayed lean side, from the best book.
    var gameDisplayOdds: String? {
        switch market.lowercased() {
        case "ml":       return (leanIsHome ? odds?.homeML : odds?.awayML) ?? line?.stringValue
        case "f5ml":      return  leanIsHome ? odds?.f5HomeML : odds?.f5AwayML
        case "spread":    return  leanIsHome ? odds?.homeSpreadOdds   : odds?.awaySpreadOdds
        case "f5spread":  return  leanIsHome ? odds?.f5HomeSpreadOdds : odds?.f5AwaySpreadOdds
        case "total":     return  leanIsUnder ? odds?.underOdds : odds?.overOdds
        default: return nil
        }
    }

    var gameBestBook: String? { odds?.book }

    /// "86°F Hitter Haven" / "Dome Pitcher-Friendly" / "Pitcher-Friendly" style
    /// badge for game-market cards, combining live weather with park factor.
    var weatherParkLabel: String? {
        guard isGameMarket else { return nil }
        let descriptor = parkFactorDescriptor
        if let condition = weather?.condition, condition.lowercased() == "dome" {
            if let descriptor { return "Dome \(descriptor)" }
            return "Dome"
        }
        if let temp = weather?.temp {
            if let descriptor { return "\(temp)°F \(descriptor)" }
            return "\(temp)°F"
        }
        return descriptor
    }

    /// Color for `weatherParkLabel` — warm tones for hitter-friendly parks,
    /// cool tones for pitcher-friendly parks, muted for neutral/dome.
    var weatherParkColor: Color {
        switch parkFactorDescriptor {
        case "Hitter Haven", "Hitter-Friendly": return .brandAmber
        case "Pitcher Haven", "Pitcher-Friendly": return .brandCyan
        default: return .brandTextDim
        }
    }

    /// Run-scoring environment descriptor derived from `parkFactor`.
    private var parkFactorDescriptor: String? {
        guard let pf = parkFactor else { return nil }
        switch pf {
        case 1.10...:     return "Hitter Haven"
        case 1.04..<1.10: return "Hitter-Friendly"
        case 1.01..<1.04: return "Slight Hitter"
        case 0.97..<1.01: return "Neutral"
        case 0.93..<0.97: return "Slight Pitcher"
        case 0.88..<0.93: return "Pitcher-Friendly"
        default:          return "Pitcher Haven"
        }
    }

    var isPitcherMarket: Bool { ["k", "outs"].contains(market.lowercased()) }
    var isGameMarket: Bool    { ["ml", "spread", "total", "nrfi", "f5ml", "f5spread"].contains(market.lowercased()) }
    var isBatterMarket: Bool  { ["hr", "hits"].contains(market.lowercased()) }

    var gradeIsHit: Bool? {
        guard gradeStatus == nil else { return nil }
        return resultHit
    }

    var displayName: String      { name ?? "Unknown" }
    var displayGameLabel: String { gameLabel ?? "" }

    /// "L"/"LHP" → "LHP", "R"/"RHP" → "RHP", nil otherwise
    var handLabel: String? {
        guard let h = hand else { return nil }
        switch h.uppercased() {
        case "L", "LHP": return "LHP"
        case "R", "RHP": return "RHP"
        default: return nil
        }
    }

    var formattedGameTime: String {
        guard let gt = gameTime,
              let date = ISO8601DateFormatter().date(from: gt) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        f.timeZone = .current
        return f.string(from: date)
    }

    var scoreColor: Color {
        switch score {
        case 80...: return .brandGreen
        case 65..<80: return .brandCyan
        case 50..<65: return .brandAmber
        default: return .brandTextMuted
        }
    }

    // Implied lean for prop markets (board always recommends the over)
    // For Spread/ML/F5 markets, prefer the team abbreviation (leanAbbr) over
    // the raw "HOME"/"AWAY" lean string, matching the web app.
    var displayLean: String {
        let teamBasedMarkets: Set<String> = ["spread", "ml", "f5ml", "f5spread"]
        if teamBasedMarkets.contains(market.lowercased()),
           let abbr = leanAbbr, !abbr.isEmpty {
            return abbr
        }
        if let l = lean { return l }
        return isPitcherMarket || isBatterMarket ? "OVER" : ""
    }

    /// Raw lean ("HOME"/"AWAY"/"OVER"/"UNDER"/"NRFI"/"YRFI") used for color
    /// lookups — kept separate from `displayLean` since Spread/ML/F5 markets
    /// display a team abbreviation but should still color by HOME/AWAY.
    var leanColorBasis: String { lean ?? displayLean }
}

// MARK: - Market enum
enum BoardMarket: String, CaseIterable, Identifiable {
    case hr, hits, k, outs, nrfi, total, ml, spread, f5ml, f5spread

    var id: String { rawValue }

    var label: String {
        switch self {
        case .hr:       return "HR"
        case .hits:     return "Hits"
        case .k:        return "K"
        case .outs:     return "Outs"
        case .nrfi:     return "NRFI"
        case .total:    return "O/U"
        case .ml:       return "ML"
        case .spread:   return "RL"
        case .f5ml:     return "F5 ML"
        case .f5spread: return "F5 RL"
        }
    }

    var color: Color {
        switch self {
        case .hr:       return .marketHR
        case .hits:     return .marketHits
        case .k:        return .marketK
        case .outs:     return .marketOuts
        case .nrfi:     return .marketNRFI
        case .total:    return .marketTotal
        case .ml:       return .marketML
        case .spread:   return .marketSpread
        case .f5ml:     return .marketF5ML
        case .f5spread: return .marketF5RL
        }
    }

    static var primaryTabs: [BoardMarket] { [.hr, .hits, .k, .outs] }
    static var gameTabs: [BoardMarket]    { [.nrfi, .total, .ml, .spread, .f5ml, .f5spread] }
}
