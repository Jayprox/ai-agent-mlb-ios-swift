import Foundation

enum Endpoints {
    // Base URL — swap to localhost:3001 for local dev
    static let baseURL = "https://ai-agent-mlb-production.up.railway.app"

    // MARK: - Auth
    static let login  = "/api/auth/login"
    static let logout = "/api/auth/logout"
    static let me     = "/api/auth/me"

    // MARK: - Slate
    static let slateBundle = "/api/slate-bundle"
    static let schedule    = "/api/schedule"

    // MARK: - Board
    static let boardSnapshot = "/api/board/snapshot"

    // MARK: - Picks
    static let picks      = "/api/picks"
    static let picksStats = "/api/picks/stats"

    static func pickVoid(id: Int)  -> String { "/api/picks/\(id)/void" }
    static func pickGrade(id: Int) -> String { "/api/picks/\(id)/grade" }

    // MARK: - Live Data
    static func linescore(gamePk: Int) -> String { "/api/linescore/\(gamePk)" }
    static func boxscore(gamePk: Int)  -> String { "/api/boxscore/\(gamePk)" }
}
