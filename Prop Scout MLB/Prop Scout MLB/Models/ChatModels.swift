import Foundation

// MARK: - AdvisorPick
struct AdvisorPick: Decodable, Identifiable {
    var id: String { "\(player ?? "?")-\(market ?? "?")-\(team ?? "?")" }
    let player: String?
    let team: String?
    let opponent: String?
    let market: String?
    let marketLabel: String?
    let line: Double?
    let lean: String?
    let odds: String?
    let confidence: String?   // "HIGH" | "MEDIUM" | "SPEC"
    let reasoning: String?
    let signals: [String]?
}

// MARK: - AdvisorParlay
struct AdvisorParlay: Decodable {
    let legs: [String]?
    let combinedOdds: String?
    let reasoning: String?
}

// MARK: - Message
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: Role
    let content: String               // plain text; compact summary text for pick responses (used in API history)
    let timestamp = Date()
    var picks: [AdvisorPick]? = nil
    var parlay: AdvisorParlay? = nil
    var responseType: String? = nil   // "picks" | "lotto" | "message"

    enum Role: String { case user, assistant }

    var hasPicksResponse: Bool { !(picks?.isEmpty ?? true) }
}

// MARK: - API types
struct ChatAPIMessage: Encodable {
    let role: String
    let content: String
}

struct ChatRequest: Encodable {
    let messages: [ChatAPIMessage]
    let persona: String
    let date: String   // today's Honolulu date — backend uses this to load the right slate
}

struct ChatResponse: Decodable {
    let type: String?
    let content: String?
    let picks: [AdvisorPick]?
    let parlay: AdvisorParlay?
    let messagesUsedToday: Int?
    let maxMessagesPerDay: Int?
}

struct ChatErrorResponse: Decodable {
    let error: String?
    let messagesUsedToday: Int?
    let maxMessagesPerDay: Int?
}
