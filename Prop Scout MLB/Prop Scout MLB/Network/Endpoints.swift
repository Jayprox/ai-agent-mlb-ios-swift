import Foundation

enum Endpoints {
    // Base URL — swap to localhost:3001 for local dev
    static let baseURL = "https://ai-agent-mlb-production.up.railway.app"

    // MARK: - Auth
    static let login       = "/api/auth/login"
    static let logout      = "/api/auth/logout"
    static let me          = "/api/auth/me"
    static let preferences = "/api/auth/preferences"

    // MARK: - Slate
    static let slateBundle = "/api/slate-bundle"
    static let schedule    = "/api/schedule"

    // MARK: - Board
    static let boardSnapshot = "/api/board/snapshot"
    static let aiBoardEdges  = "/api/ai-board/edges"

    // MARK: - Picks
    static let picks      = "/api/picks"
    static let picksStats = "/api/picks/stats"

    static func pickVoid(id: String)  -> String { "/api/picks/\(id)/void" }
    static func pickGrade(id: String) -> String { "/api/picks/\(id)/grade" }

    // MARK: - Leaderboard
    static let leaderboard = "/api/leaderboard"

    // MARK: - Live Data
    static func linescore(gamePk: Int) -> String { "/api/linescore/\(gamePk)" }
    static func boxscore(gamePk: Int)  -> String { "/api/boxscore/\(gamePk)" }
}
