import Foundation
import SwiftUI

// MARK: - Park factor data

struct ParkFactor {
    let hr: Double
    let hit: Double
    let k: Double
    let label: String
}

private let NEUTRAL_PARK = ParkFactor(hr: 1.0, hit: 1.0, k: 1.0, label: "Neutral")

// swiftlint:disable identifier_name
private let PARK_FACTORS: [String: ParkFactor] = [
    "COL": .init(hr: 1.35, hit: 1.15, k: 0.93, label: "Hitter Haven"),
    "CIN": .init(hr: 1.15, hit: 1.05, k: 0.97, label: "Hitter-Friendly"),
    "PHI": .init(hr: 1.10, hit: 1.04, k: 0.98, label: "Hitter-Friendly"),
    "BOS": .init(hr: 1.08, hit: 1.09, k: 0.97, label: "Hitter-Friendly"),
    "TEX": .init(hr: 1.08, hit: 1.03, k: 0.98, label: "Hitter-Friendly"),
    "BAL": .init(hr: 1.07, hit: 1.03, k: 0.99, label: "Hitter-Friendly"),
    "CHC": .init(hr: 1.04, hit: 1.02, k: 0.99, label: "Neutral (wind-variable)"),
    "NYY": .init(hr: 1.05, hit: 1.01, k: 1.00, label: "Slight Hitter"),
    "TOR": .init(hr: 1.03, hit: 1.02, k: 1.00, label: "Slight Hitter"),
    "ARI": .init(hr: 1.02, hit: 1.01, k: 0.99, label: "Slight Hitter"),
    "ATL": .init(hr: 1.02, hit: 1.01, k: 1.00, label: "Neutral"),
    "DET": .init(hr: 1.01, hit: 1.00, k: 1.00, label: "Neutral"),
    "MIL": .init(hr: 1.00, hit: 1.01, k: 1.00, label: "Neutral"),
    "CHW": .init(hr: 1.00, hit: 1.00, k: 1.00, label: "Neutral"),
    "STL": .init(hr: 0.98, hit: 0.99, k: 1.01, label: "Slight Pitcher"),
    "WSH": .init(hr: 0.98, hit: 0.99, k: 1.00, label: "Slight Pitcher"),
    "MIN": .init(hr: 0.97, hit: 0.99, k: 1.01, label: "Slight Pitcher"),
    "CLE": .init(hr: 0.97, hit: 0.99, k: 1.00, label: "Slight Pitcher"),
    "PIT": .init(hr: 0.96, hit: 0.98, k: 1.01, label: "Pitcher-Friendly"),
    "NYM": .init(hr: 0.96, hit: 0.98, k: 1.01, label: "Pitcher-Friendly"),
    "LAA": .init(hr: 0.96, hit: 0.98, k: 1.01, label: "Pitcher-Friendly"),
    "HOU": .init(hr: 0.95, hit: 0.99, k: 1.01, label: "Pitcher-Friendly"),
    "MIA": .init(hr: 0.94, hit: 0.98, k: 1.02, label: "Pitcher-Friendly"),
    "TB":  .init(hr: 0.94, hit: 0.97, k: 1.02, label: "Pitcher-Friendly"),
    "OAK": .init(hr: 0.93, hit: 0.97, k: 1.01, label: "Pitcher-Friendly"),
    "LAD": .init(hr: 0.93, hit: 0.97, k: 1.02, label: "Pitcher-Friendly"),
    "KC":  .init(hr: 0.91, hit: 0.98, k: 1.01, label: "Pitcher-Friendly"),
    "SEA": .init(hr: 0.90, hit: 0.97, k: 1.02, label: "Pitcher-Friendly"),
    "SD":  .init(hr: 0.87, hit: 0.96, k: 1.03, label: "Pitcher Haven"),
    "SF":  .init(hr: 0.83, hit: 0.96, k: 1.03, label: "Pitcher Haven"),
]
// swiftlint:enable identifier_name

// MARK: - Builder

enum WhyFactorsBuilder {

    /// Returns [ScoreSignal] for the Why? modal.
    /// Prop markets (K/Outs/HR/Hits) are computed client-side.
    /// Game markets (ML/Spread/Total/NRFI/F5) use candidate.factors from the API.
    static func build(for candidate: BoardCandidate) -> [ScoreSignal] {
        if candidate.isGameMarket {
            return apiFactors(candidate)
        }
        switch candidate.market.lowercased() {
        case "k":    return kFactors(candidate)
        case "outs": return outsFactors(candidate)
        case "hr":   return hrFactors(candidate)
        case "hits": return hitsFactors(candidate)
        default:     return []
        }
    }

    // MARK: - Game market (API-provided factors)

    private static func apiFactors(_ c: BoardCandidate) -> [ScoreSignal] {
        (c.factors ?? []).map { f in
            ScoreSignal(label: f.label,
                        earned: Double(f.pts),
                        max: Double(f.max),
                        value: f.value,
                        description: f.detail)
        }
    }

    // MARK: - Park lookup

    private static func parkInfo(for gameLabel: String) -> (abbr: String, pf: ParkFactor) {
        let abbr = gameLabel.components(separatedBy: " @ ").last?.trimmingCharacters(in: .whitespaces) ?? ""
        return (abbr, PARK_FACTORS[abbr] ?? NEUTRAL_PARK)
    }

    private static func pctStr(_ delta: Double) -> String {
        let p = Int((delta * 100).rounded())
        return p >= 0 ? "+\(p)%" : "\(p)%"
    }

    // MARK: - K factors (5 signals, max 95)

    private static func kFactors(_ c: BoardCandidate) -> [ScoreSignal] {
        var out: [ScoreSignal] = []

        // 1. K/9  (max 30)
        if let raw = c.k9, let v = Double(raw) {
            let (pts, detail): (Int, String) = {
                if v >= 10.0 { return (30, "Elite swing-and-miss (≥10)") }
                if v >= 9.0  { return (22, "Very good (≥9)") }
                if v >= 8.0  { return (14, "Above avg (≥8)") }
                if v >= 7.0  { return (7,  "Solid (≥7)") }
                return (0, "Below avg")
            }()
            out.append(.init(label: "K/9", earned: Double(pts), max: 30, value: raw, description: detail))
        }

        // 2. L3 Avg K  (max 22)
        if let raw = c.avgK3, let v = Double(raw) {
            let (pts, detail): (Int, String) = {
                if v >= 7 { return (22, "Strong recent K production") }
                if v >= 6 { return (16, "Good recent production") }
                if v >= 5 { return (10, "Average production") }
                if v >= 4 { return (5,  "Modest production") }
                return (0, "Low recent production")
            }()
            out.append(.init(label: "L3 Avg K", earned: Double(pts), max: 22,
                             value: "\(raw)K/start", description: detail))
        }

        // 3. Park – K factor  (max 18)
        let (abbr, pf) = parkInfo(for: c.displayGameLabel)
        let kPts = max(-18, min(18, Int(((pf.k - 1.0) * 90).rounded())))
        let kDetail: String = {
            if pf.k >= 1.05 { return "K-friendly park (\(pctStr(pf.k - 1.0)))" }
            if pf.k <= 0.95 { return "K-suppressing (\(pctStr(pf.k - 1.0)))" }
            return "Neutral park"
        }()
        out.append(.init(label: "Park (K Factor)", earned: Double(kPts), max: 18,
                         value: abbr.isEmpty ? "N/A" : abbr, description: kDetail))

        // 4. Umpire  (max 15)
        let (uPts, uDetail): (Int, String) = {
            switch c.umpireRating {
            case "pitcher": return (15, "Tight zone — historically boosts K rates")
            case "hitter":  return (3,  "Wide zone — suppresses Ks")
            case "neutral": return (8,  "Average zone")
            default:        return (8,  "Not yet assigned")
            }
        }()
        out.append(.init(label: "Umpire", earned: Double(uPts), max: 15,
                         value: c.umpire ?? "TBD", description: uDetail))

        // 5. WHIP  (max 10)
        if let raw = c.whip, let v = Double(raw) {
            let (pts, detail): (Int, String) = {
                if v <= 1.05 { return (10, "Elite control — stays in games") }
                if v <= 1.20 { return (6,  "Good control") }
                if v <= 1.35 { return (2,  "Average control") }
                return (0, "Elevated baserunners — risk of early hook")
            }()
            out.append(.init(label: "WHIP", earned: Double(pts), max: 10, value: raw, description: detail))
        }

        return out
    }

    // MARK: - Outs factors (4 signals, max 85)

    private static func outsFactors(_ c: BoardCandidate) -> [ScoreSignal] {
        var out: [ScoreSignal] = []

        // 1. Avg IP  (max 35)
        if let raw = c.avgIP, let ip = parseIP(raw) {
            let (pts, detail): (Int, String) = {
                if ip >= 6.5 { return (35, "Goes deep — 6.5+ IP avg") }
                if ip >= 6.0 { return (26, "Quality starts — 6+ IP avg") }
                if ip >= 5.5 { return (17, "Solid depth — 5.5+ IP avg") }
                if ip >= 5.0 { return (8,  "Average depth — ~5 IP") }
                return (0, "Short outings — risky for outs props")
            }()
            out.append(.init(label: "Avg IP", earned: Double(pts), max: 35,
                             value: "\(raw) IP/start", description: detail))
        }

        // 2. WHIP  (max 28)
        if let raw = c.whip, let v = Double(raw) {
            let (pts, detail): (Int, String) = {
                if v <= 1.00 { return (28, "Elite control — extends outings") }
                if v <= 1.10 { return (20, "Very good control") }
                if v <= 1.20 { return (12, "Good control") }
                if v <= 1.35 { return (5,  "Average control") }
                return (0, "Elevated baserunners — pitch count climbs fast")
            }()
            out.append(.init(label: "WHIP", earned: Double(pts), max: 28, value: raw, description: detail))
        }

        // 3. ERA  (max 12)
        if let raw = c.era, let v = Double(raw) {
            let (pts, detail): (Int, String) = {
                if v <= 3.0 { return (10, "Elite — limiting runs, keeps manager trust") }
                if v <= 3.5 { return (7,  "Very good") }
                if v <= 4.5 { return (3,  "Average — occasional rough starts") }
                return (0, "Struggling — early exits more likely")
            }()
            out.append(.init(label: "ERA", earned: Double(pts), max: 12, value: raw, description: detail))
        }

        // 4. Park – hit suppression  (max 10)
        let (abbr, pf) = parkInfo(for: c.displayGameLabel)
        let hPts = max(-10, min(10, Int(((1.0 - pf.hit) * 50).rounded())))
        let hDetail: String = {
            if pf.hit <= 0.95 { return "Pitcher-friendly — suppresses hits (\(pctStr(1.0 - pf.hit)))" }
            if pf.hit >= 1.08 { return "Hitter-friendly — pitch count rises (\(pctStr(pf.hit - 1.0)))" }
            return "Neutral park"
        }()
        out.append(.init(label: "Park (Hit Factor)", earned: Double(hPts), max: 10,
                         value: abbr.isEmpty ? "N/A" : abbr, description: hDetail))

        return out
    }

    // MARK: - HR factors (4–5 signals, max 51+)

    private static func hrFactors(_ c: BoardCandidate) -> [ScoreSignal] {
        var out: [ScoreSignal] = []

        // 1. Power — prefer SLG, fallback to OPS  (max 20)
        let slgVal = c.slg.flatMap { Double($0) } ?? 0
        let opsVal = c.ops.flatMap { Double($0) } ?? 0
        let useSlg = slgVal > 0
        if useSlg || opsVal > 0 {
            let pts = useSlg
                ? max(-12, min(20, Int((slgVal - 0.410) * 55)))
                : max(-12, min(20, Int((opsVal - 0.720) * 20)))
            let detail: String = {
                let v = useSlg ? slgVal : opsVal
                if useSlg {
                    if v >= 0.500 { return "Power hitter (.500+ SLG)" }
                    if v >= 0.440 { return "Above-avg power (.440+)" }
                    if v >= 0.380 { return "Average power" }
                    return "Below-avg power — few extra-base hits"
                } else {
                    if v >= 0.800 { return "Strong OPS (.800+)" }
                    if v >= 0.720 { return "Average OPS (.720+)" }
                    return "Below-avg OPS — limited power"
                }
            }()
            let display = useSlg ? "\(c.slg ?? "") SLG" : "\(c.ops ?? "") OPS"
            out.append(.init(label: "Power", earned: Double(pts), max: 20, value: display, description: detail))
        }

        // 2. HR pace  (max 15)
        if let raw = c.hrTotal, let hr = Int(raw) {
            let pts = min(15, Int(Double(hr) * 0.7))
            let detail: String = {
                if hr >= 20 { return "High HR pace — proven power" }
                if hr >= 10 { return "Moderate HR pace" }
                if hr >= 5  { return "Low HR pace" }
                return "Very few HRs this season"
            }()
            out.append(.init(label: "HR Pace", earned: Double(pts), max: 15,
                             value: "\(hr) HR this season", description: detail))
        }

        // 3. Park – HR factor  (max 10)
        let (abbr, pf) = parkInfo(for: c.displayGameLabel)
        let hrPts = max(-10, min(10, Int(((pf.hr - 1.0) * 35).rounded())))
        let hrDetail: String = {
            if pf.hr >= 1.10 { return "HR-friendly (\(pctStr(pf.hr - 1.0)))" }
            if pf.hr <= 0.90 { return "HR-suppressing (\(pctStr(pf.hr - 1.0)))" }
            return "Neutral park for HRs"
        }()
        out.append(.init(label: "Park (HR Factor)", earned: Double(hrPts), max: 10,
                         value: abbr.isEmpty ? "N/A" : abbr, description: hrDetail))

        // 4. Wind — conditional, only when favourable  (max 8)
        if c.windFav == true {
            out.append(.init(label: "Wind", earned: 8, max: 8,
                             value: "Blowing out",
                             description: "Wind out to CF/RF — historically adds 5–8% to HR rates"))
        }

        // 5. Batting order  (max 6)
        if let order = c.order {
            let (pts, detail): (Int, String) = {
                if order <= 3 { return (6,  "Premium spot — most PA, best lineup protection") }
                if order <= 5 { return (3,  "Middle of order") }
                if order >= 8 { return (-4, "Bottom of order — fewer PA") }
                return (0, "Lower-middle order")
            }()
            out.append(.init(label: "Batting Order", earned: Double(pts), max: 6,
                             value: "#\(order)", description: detail))
        }

        return out
    }

    // MARK: - Hits factors (4 signals, max 42)

    private static func hitsFactors(_ c: BoardCandidate) -> [ScoreSignal] {
        var out: [ScoreSignal] = []

        // 1. Season AVG — prefer AVG, fallback to OPS  (max 20)
        let avgVal = c.avg.flatMap { Double($0) } ?? 0
        let opsVal = c.ops.flatMap { Double($0) } ?? 0
        let useAvg = avgVal > 0
        if useAvg || opsVal > 0 {
            let pts = useAvg
                ? max(-12, min(20, Int((avgVal - 0.250) * 140)))
                : max(-12, min(20, Int((opsVal - 0.720) * 15)))
            let detail: String = {
                let v = useAvg ? avgVal : opsVal
                if useAvg {
                    if v >= 0.300 { return "Excellent contact hitter (.300+)" }
                    if v >= 0.270 { return "Good hitter (.270+)" }
                    if v >= 0.240 { return "Average (.240+)" }
                    return "Struggling — below .240"
                } else {
                    if v >= 0.800 { return "Strong OPS (.800+)" }
                    if v >= 0.720 { return "Average OPS" }
                    return "Below-avg OPS"
                }
            }()
            let display = useAvg ? "\(c.avg ?? "") AVG" : "\(c.ops ?? "") OPS"
            out.append(.init(label: "Season AVG", earned: Double(pts), max: 20, value: display, description: detail))
        }

        // 2. Recent form L5  (max 8)
        if let hitRate = c.hitRate {
            let l5 = hitRate.prefix(5).compactMap { $0 }.reduce(0, +)
            let pts = max(0, min(8, Int((Double(l5) / 5.0 - 0.40) * 28)))
            let detail: String = {
                if l5 >= 4 { return "Hot — on a tear recently" }
                if l5 >= 3 { return "Consistent — hitting in most games" }
                if l5 >= 2 { return "Mixed — some cold games" }
                return "Cold — struggling to get on base"
            }()
            out.append(.init(label: "Recent Form (L5)", earned: Double(pts), max: 8,
                             value: "\(l5)/5 games with a hit", description: detail))
        }

        // 3. Park – hit factor  (max 8)
        let (abbr, pf) = parkInfo(for: c.displayGameLabel)
        let hitPts = max(-8, min(8, Int(((pf.hit - 1.0) * 28).rounded())))
        let hitDetail: String = {
            if pf.hit >= 1.08 { return "Hitter-friendly (\(pctStr(pf.hit - 1.0)))" }
            if pf.hit <= 0.93 { return "Pitcher-friendly (\(pctStr(pf.hit - 1.0)))" }
            return "Neutral park for hits"
        }()
        out.append(.init(label: "Park (Hit Factor)", earned: Double(hitPts), max: 8,
                         value: abbr.isEmpty ? "N/A" : abbr, description: hitDetail))

        // 4. Batting order  (max 6)
        if let order = c.order {
            let (pts, detail): (Int, String) = {
                if order <= 3 { return (6,  "Premium spot — most PA, best lineup protection") }
                if order <= 5 { return (3,  "Middle of order") }
                if order >= 8 { return (-4, "Bottom of order — fewer PA") }
                return (0, "Lower-middle order")
            }()
            out.append(.init(label: "Batting Order", earned: Double(pts), max: 6,
                             value: "#\(order)", description: detail))
        }

        return out
    }

    // MARK: - IP parser (baseball notation: "6.1" = 6⅓ IP, "6.2" = 6⅔ IP)

    private static func parseIP(_ s: String) -> Double? {
        let parts = s.split(separator: ".")
        guard let whole = Double(parts[0]) else { return nil }
        let outs = parts.count > 1 ? Double(parts[1]) ?? 0 : 0
        return whole + outs / 3.0
    }
}
