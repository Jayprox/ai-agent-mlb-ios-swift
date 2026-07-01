import Foundation

// MARK: - Linescore response
struct LinescoreResponse: Decodable {
    let gamePk: Int
    let inning: Int?
    let halfInning: String?  // "top" or "bottom"
    let awayScore: Int?
    let homeScore: Int?
    let firstInning: FirstInningRuns?

    enum CodingKeys: String, CodingKey {
        case gamePk, inning, halfInning, awayScore, homeScore, firstInning
    }
}

// MARK: - First inning runs (for NRFI)
struct FirstInningRuns: Decodable {
    let away: Int?
    let home: Int?
}
