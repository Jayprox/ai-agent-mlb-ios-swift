import Foundation

// MARK: - Leaderboard Entry
struct LeaderboardEntry: Decodable, Identifiable {
    let rank: Int
    let userId: String
    let username: String
    let winRate: Double
    let winRatePct: String
    let pnl: Double
    let gradedPicks: Int
    let hits: Int
    let misses: Int
    let pushes: Int
    let totalPicks: Int

    var id: String { userId }

    enum CodingKeys: String, CodingKey {
        case rank, userId, username, winRate, winRatePct, pnl, gradedPicks, hits, misses, pushes, totalPicks
    }
}

// MARK: - Leaderboard Response
struct LeaderboardResponse: Decodable {
    let leaderboard: [LeaderboardEntry]
    let totalUsers: Int
    let sortedBy: String
    let minGradedPicks: Int
    let unavailable: Bool?

    enum CodingKeys: String, CodingKey {
        case leaderboard, totalUsers, sortedBy, minGradedPicks, unavailable
    }
}

// MARK: - User Stats (from /me endpoint)
struct UserLeaderboardStats: Decodable {
    let optIn: Bool
    let username: String?
    let meetsThreshold: Bool
    let minGradedPicks: Int
    let stats: UserStats
    let rank: Int?

    enum CodingKeys: String, CodingKey {
        case optIn, username, meetsThreshold, minGradedPicks, stats, rank
    }
}

// MARK: - User Stats Details
struct UserStats: Decodable {
    let gradedPicks: Int
    let hits: Int
    let misses: Int
    let pushes: Int
    let totalPicks: Int
    let winRate: Double
    let winRatePct: String
    let pnl: Double

    enum CodingKeys: String, CodingKey {
        case gradedPicks, hits, misses, pushes, totalPicks, winRate, winRatePct, pnl
    }
}

// MARK: - Opt-in Request/Response
struct LeaderboardOptInRequest: Encodable {
    let username: String

    enum CodingKeys: String, CodingKey {
        case username
    }
}

struct LeaderboardOptInResponse: Decodable {
    let ok: Bool
    let optIn: Bool
    let username: String

    enum CodingKeys: String, CodingKey {
        case ok, optIn, username
    }
}

// MARK: - Opt-out Response
struct LeaderboardOptOutResponse: Decodable {
    let ok: Bool
    let optIn: Bool

    enum CodingKeys: String, CodingKey {
        case ok, optIn
    }
}

// MARK: - Sort Option
enum LeaderboardSortBy: String, CaseIterable {
    case winRate = "win_rate"
    case pnl = "pnl"

    var label: String {
        switch self {
        case .winRate: return "Win Rate"
        case .pnl: return "P&L"
        }
    }
}
