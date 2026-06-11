import Foundation

enum PickGradingEngine {
    static func grade(
        pick: Pick,
        boxscores: [Int: Boxscore],
        linescores: [Int: LinescoreData]
    ) -> GradePickRequest? {
        if isGameMarket(pick.market) {
            return gradeGamePick(pick: pick, linescores: linescores, boxscores: boxscores)
        }
        return gradePropPick(pick: pick, boxscores: boxscores)
    }

    static func ipToOuts(_ ip: String) -> Int {
        let parts = ip.split(separator: ".", omittingEmptySubsequences: false)
        let innings   = Int(parts.first ?? "0") ?? 0
        let remainder = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        return (innings * 3) + remainder
    }

    private static func isGameMarket(_ market: String) -> Bool {
        ["ml", "spread", "total", "nrfi", "f5ml", "f5spread"].contains(market.lowercased())
    }

    // MARK: - Game picks
    private static func gradeGamePick(
        pick: Pick,
        linescores: [Int: LinescoreData],
        boxscores: [Int: Boxscore]
    ) -> GradePickRequest? {
        guard let gamePk = Int(pick.playerId ?? "") else { return nil }

        // ML / Spread / Total use final score from linescore endpoint
        switch pick.market.lowercased() {
        case "ml":
            guard let ls = linescores[gamePk] else { return nil }
            let awayWon = ls.awayScore > ls.homeScore
            let hit = (pick.side ?? "HOME") == "AWAY" ? awayWon : !awayWon
            return GradePickRequest(resultHit: hit, actualStat: hit ? 1 : 0, gradeStatus: nil)

        case "spread":
            guard let ls = linescores[gamePk] else { return nil }
            let line = pick.bookLine ?? 1.5
            let diff = (pick.side ?? "HOME") == "AWAY"
                ? ls.awayScore - ls.homeScore
                : ls.homeScore - ls.awayScore
            let actual = Double(diff)
            if actual + line == 0 {
                return GradePickRequest(resultHit: nil, actualStat: actual, gradeStatus: "push")
            }
            return GradePickRequest(resultHit: actual + line > 0, actualStat: actual, gradeStatus: nil)

        case "total":
            guard let ls = linescores[gamePk] else { return nil }
            let total = Double(ls.awayScore + ls.homeScore)
            let line  = pick.bookLine ?? 8.5
            if total == line {
                return GradePickRequest(resultHit: nil, actualStat: total, gradeStatus: "push")
            }
            let hit = (pick.side ?? "OVER") == "OVER" ? total > line : total < line
            return GradePickRequest(resultHit: hit, actualStat: total, gradeStatus: nil)

        // NRFI / F5 need per-inning data — use boxscore.linescore.innings
        case "nrfi":
            guard let innings = boxscores[gamePk]?.linescore?.innings,
                  let first = innings.first(where: { $0.num == 1 }) else { return nil }
            let scored = Double((first.away ?? 0) + (first.home ?? 0))
            let hit    = (pick.side ?? "NRFI") == "NRFI" ? scored == 0 : scored > 0
            return GradePickRequest(resultHit: hit, actualStat: scored, gradeStatus: nil)

        case "f5ml":
            guard let innings = boxscores[gamePk]?.linescore?.innings else { return nil }
            let f5 = innings.filter { $0.num <= 5 }
            guard f5.count >= 5 else { return nil }
            let awayF5 = f5.reduce(0) { $0 + ($1.away ?? 0) }
            let homeF5 = f5.reduce(0) { $0 + ($1.home ?? 0) }
            if awayF5 == homeF5 {
                return GradePickRequest(resultHit: nil, actualStat: nil, gradeStatus: "push")
            }
            let awayWon = awayF5 > homeF5
            return GradePickRequest(
                resultHit: (pick.side ?? "HOME") == "AWAY" ? awayWon : !awayWon,
                actualStat: nil,
                gradeStatus: nil
            )

        case "f5spread":
            guard let innings = boxscores[gamePk]?.linescore?.innings else { return nil }
            let f5 = innings.filter { $0.num <= 5 }
            guard f5.count >= 5 else { return nil }
            let awayF5 = f5.reduce(0) { $0 + ($1.away ?? 0) }
            let homeF5 = f5.reduce(0) { $0 + ($1.home ?? 0) }
            let line   = pick.bookLine ?? 1.5
            let diff   = (pick.side ?? "HOME") == "AWAY" ? awayF5 - homeF5 : homeF5 - awayF5
            let actual = Double(diff)
            if actual + line == 0 {
                return GradePickRequest(resultHit: nil, actualStat: actual, gradeStatus: "push")
            }
            return GradePickRequest(resultHit: actual + line > 0, actualStat: actual, gradeStatus: nil)

        default:
            return nil
        }
    }

    // MARK: - Prop picks
    private static func gradePropPick(
        pick: Pick,
        boxscores: [Int: Boxscore]
    ) -> GradePickRequest? {
        guard let playerId = pick.playerId else { return nil }

        for boxscore in boxscores.values where boxscore.isComplete {
            let allBatters  = (boxscore.batting?.away  ?? []) + (boxscore.batting?.home  ?? [])
            let allPitchers = (boxscore.pitching?.away ?? []) + (boxscore.pitching?.home ?? [])

            switch pick.market.lowercased() {
            case "hr":
                guard let batter = allBatters.first(where: { $0.id?.stringValue == playerId }) else { continue }
                if batter.ab == 0 {
                    return GradePickRequest(resultHit: nil, actualStat: nil, gradeStatus: "scratch")
                }
                let hr   = Double(batter.hr ?? 0)
                let line = pick.bookLine ?? 0.5
                if hr == line { return GradePickRequest(resultHit: nil, actualStat: hr, gradeStatus: "push") }
                let hit = (pick.side ?? "OVER") == "OVER" ? hr > line : hr < line
                return GradePickRequest(resultHit: hit, actualStat: hr, gradeStatus: nil)

            case "hits":
                guard let batter = allBatters.first(where: { $0.id?.stringValue == playerId }) else { continue }
                if batter.ab == 0 {
                    return GradePickRequest(resultHit: nil, actualStat: nil, gradeStatus: "scratch")
                }
                let hits = Double(batter.h ?? 0)
                let line = pick.bookLine ?? 0.5
                if hits == line { return GradePickRequest(resultHit: nil, actualStat: hits, gradeStatus: "push") }
                let hit = (pick.side ?? "OVER") == "OVER" ? hits > line : hits < line
                return GradePickRequest(resultHit: hit, actualStat: hits, gradeStatus: nil)

            case "k":
                guard let pitcher = allPitchers.first(where: { $0.id?.stringValue == playerId }) else { continue }
                let ks   = Double(pitcher.k ?? 0)
                let line = pick.bookLine ?? 4.5
                if ks == line { return GradePickRequest(resultHit: nil, actualStat: ks, gradeStatus: "push") }
                let hit = (pick.side ?? "OVER") == "OVER" ? ks > line : ks < line
                return GradePickRequest(resultHit: hit, actualStat: ks, gradeStatus: nil)

            case "outs":
                guard let pitcher = allPitchers.first(where: { $0.id?.stringValue == playerId }) else { continue }
                let outs = Double(ipToOuts(pitcher.ip ?? "0.0"))
                let line = pick.bookLine ?? 17.5
                if outs == line { return GradePickRequest(resultHit: nil, actualStat: outs, gradeStatus: "push") }
                let hit = (pick.side ?? "OVER") == "OVER" ? outs > line : outs < line
                return GradePickRequest(resultHit: hit, actualStat: outs, gradeStatus: nil)

            default:
                return nil
            }
        }

        return nil
    }
}

extension IntOrString {
    var stringValue: String {
        switch self {
        case .int(let v):    return String(v)
        case .string(let v): return v
        }
    }
}
