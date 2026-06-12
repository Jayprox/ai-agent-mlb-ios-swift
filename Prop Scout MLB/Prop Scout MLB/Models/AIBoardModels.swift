import Foundation
import SwiftUI

// MARK: - AI Board response
struct AIBoardResponse: Decodable {
    let edges: [AIBoardEdge]
    let generatedAt: String?
    let slateDate: String?
    let fallback: Bool?
}

// MARK: - Edge candidate (all fields optional except aiScore)
struct AIBoardEdge: Identifiable {
    let rawId: String?
    let market: String?
    let playerName: String?
    let team: String?
    let gameLabel: String?
    let score: Int?
    let aiScore: Int
    let simConfidence: Int?
    let bookLine: Double?
    let edge: Double?
    let aiReason: String?
    let lean: String?
    let resultHit: Bool?
    let gradeStatus: String?
    let impliedProb: Double?
    let candidate: BoardCandidate?

    var id: String { rawId ?? "\(market ?? "")-\(gameLabel ?? "")-\(aiScore)" }

    /// MLB player ID for this edge, used when logging a pick. The edge's own
    /// `rawId` (from the top-level "id" field) is a composite/edge identifier,
    /// not a player ID — the real MLB player ID lives on the embedded
    /// `candidate`. Falls back to parsing `rawId` as a number in case it's
    /// ever a bare numeric player ID (e.g. game-market edges with no candidate).
    var playerId: Int? { candidate?.rawId ?? rawId.flatMap { Int($0) } }

    var displayName: String      { playerName ?? gameLabel ?? "—" }
    var displayGameLabel: String { gameLabel ?? "" }
    var displayMarket: String    { market ?? "—" }

    var isHit: Bool     { resultHit == true  && gradeStatus == nil }
    var isMiss: Bool    { resultHit == false && gradeStatus == nil }
    var isPPD: Bool     { gradeStatus == "ppd" }
    var isScratch: Bool { gradeStatus == "scratch" }

    // MARK: - Model Picks helpers

    /// Player-prop markets eligible for the "Model Picks" tab.
    private static let modelMarkets: Set<String> = ["k", "outs", "hr", "hits"]

    /// True if this edge is a player-prop pick with a verified market line —
    /// the set of edges shown on the Model Picks tab.
    var isModelPick: Bool {
        guard let m = market?.lowercased(), Self.modelMarkets.contains(m) else { return false }
        return candidate?.propLine != nil
    }

    /// "K" / "Outs" / "HR" / "Hits" market label, preferring the book's label.
    var pickMarketLabel: String {
        candidate?.propLine?.marketLabel ?? displayMarket.uppercased()
    }

    /// Confidence tier used for grouping on the Model Picks tab.
    var confidenceTier: ModelConfidenceTier {
        let c = simConfidence ?? 0
        if c >= 70 { return .high }
        if c >= 50 { return .medium }
        return .low
    }

    /// The book line shown in the title, e.g. "K O/U 6.5".
    var pickBookLine: Double? { candidate?.propLine?.line }

    /// The model's projected value, e.g. "Est. 8.5".
    var projectedLine: Double? { candidate?.suggestedLine }

    /// Best book + odds for the displayed lean side.
    var bestBookLabel: String? { candidate?.propLine?.book }
    var bestBookOdds: String? {
        guard let pl = candidate?.propLine else { return nil }
        return (lean ?? "OVER").uppercased() == "UNDER" ? pl.underOdds : pl.overOdds
    }

    /// Per-book lines/odds for the LINES row, sorted by book code.
    var bookChips: [(book: String, line: Double?, odds: String?)] {
        guard let books = candidate?.propLine?.books else { return [] }
        let isUnder = (lean ?? "OVER").uppercased() == "UNDER"
        return books.compactMap { key, value -> (String, Double?, String?)? in
            guard let value else { return nil }
            return (key, value.line, isUnder ? value.underOdds : value.overOdds)
        }
        .sorted { $0.0 < $1.0 }
    }

    /// "ERA 2.97 — Elite ..." style factor bullets, computed client-side via WhyFactorsBuilder.
    var factorSignals: [ScoreSignal] {
        guard let candidate else { return [] }
        return WhyFactorsBuilder.build(for: candidate)
    }

    // MARK: - Predict helpers

    /// True if this edge is a player-prop pick where the model's simulated probability
    /// exceeds the book's implied probability — the set shown on the Predict tab.
    var isPredictPick: Bool {
        guard let m = market?.lowercased(), Self.modelMarkets.contains(m) else { return false }
        guard let edge, edge > 0 else { return false }
        return simConfidence != nil && impliedProb != nil
    }

    /// Model simulation confidence, 0-100.
    var simPct: Int? { simConfidence }

    /// Book's implied probability, 0-100, rounded.
    var bookPct: Int? {
        guard let impliedProb else { return nil }
        return Int((impliedProb * 100).rounded())
    }

    /// Edge in percentage points, e.g. "+36".
    var edgePts: Int? {
        guard let edge else { return nil }
        return Int((edge * 100).rounded())
    }

    // MARK: - Scout helpers

    /// Short bettor-style blurb for a Scout slate pick: existing AI reasoning
    /// plus a lean + unit framing, or a fallback if no reasoning is available.
    var scoutReasoning: String {
        let leanText = (lean ?? "OVER").uppercased()
        if let reason = aiReason, !reason.isEmpty {
            return "\(reason) Lean \(leanText) for 1u at -110."
        }
        return "\(displayName) projects as a \(leanText) lean — solid spot for 1u at -110."
    }

    /// "K Prop" / "Outs" / "HR Prop" / "Hits Prop" style market label for the Predict tab.
    var predictMarketLabel: String {
        switch market?.lowercased() {
        case "k":    return "K Prop"
        case "outs": return "Outs"
        case "hr":   return "HR Prop"
        case "hits": return "Hits Prop"
        default:     return displayMarket.uppercased()
        }
    }

    var aiScoreColor: Color {
        switch aiScore {
        case 80...: return .brandGreen
        case 65..<80: return .brandCyan
        default: return .brandAmber
        }
    }

    var algScoreColor: Color {
        switch score ?? 0 {
        case 80...: return .brandGreen
        case 65..<80: return .brandCyan
        default: return .brandTextMuted
        }
    }
}

// MARK: - Custom Decodable — everything optional, never throws
extension AIBoardEdge: Decodable {
    enum CodingKeys: String, CodingKey {
        case rawId = "id"
        case market, playerName, team, gameLabel, score, aiScore
        case simConfidence, bookLine, edge, aiReason, lean
        case resultHit, gradeStatus, impliedProb
        case candidate = "_candidate"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        rawId          = try? c.decode(String.self,  forKey: .rawId)
        market         = try? c.decode(String.self,  forKey: .market)
        playerName     = try? c.decode(String.self,  forKey: .playerName)
        team           = try? c.decode(String.self,  forKey: .team)
        gameLabel      = try? c.decode(String.self,  forKey: .gameLabel)
        score          = try? c.decode(Int.self,     forKey: .score)
        aiScore        = (try? c.decode(Int.self,    forKey: .aiScore)) ?? 0
        simConfidence  = try? c.decode(Int.self,     forKey: .simConfidence)
        bookLine       = try? c.decode(Double.self,  forKey: .bookLine)
        edge           = try? c.decode(Double.self,  forKey: .edge)
        aiReason       = try? c.decode(String.self,  forKey: .aiReason)
        lean           = try? c.decode(String.self,  forKey: .lean)
        resultHit      = try? c.decode(Bool.self,    forKey: .resultHit)
        gradeStatus    = try? c.decode(String.self,  forKey: .gradeStatus)
        impliedProb    = try? c.decode(Double.self,  forKey: .impliedProb)

        // Decode the embedded candidate (player-prop or game-market shape) and
        // inject the edge's market string, matching BoardSnapshot.candidates(for:).
        if var cand = try? c.decode(BoardCandidate.self, forKey: .candidate) {
            cand.market = market ?? ""
            candidate = cand
        } else {
            candidate = nil
        }
    }
}

// MARK: - Model Picks confidence tier
enum ModelConfidenceTier: String, CaseIterable, Hashable {
    case high   = "HIGH CONFIDENCE"
    case medium = "MEDIUM CONFIDENCE"
    case low    = "LOW CONFIDENCE"
}

// MARK: - Filter
enum AIBoardFilter: String, CaseIterable, Identifiable {
    case all  = "All"
    case k    = "K"
    case outs = "Outs"
    case hr   = "HR"
    case hits = "Hits"
    case f5ml = "F5 ML"

    var id: String { rawValue }

    func matches(_ edge: AIBoardEdge) -> Bool {
        switch self {
        case .all:  return true
        case .k:    return edge.market?.lowercased() == "k"
        case .outs: return edge.market?.lowercased() == "outs"
        case .hr:   return edge.market?.lowercased() == "hr"
        case .hits: return edge.market?.lowercased() == "hits"
        case .f5ml: return ["f5ml","f5spread"].contains(edge.market?.lowercased() ?? "")
        }
    }
}
