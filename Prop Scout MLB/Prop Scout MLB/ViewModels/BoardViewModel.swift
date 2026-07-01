import Foundation
import Combine

final class BoardViewModel: ObservableObject {
    @Published var snapshot: BoardSnapshot? = nil
    @Published var slateOddsByGamePk: [Int: OddsData] = [:]
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String? = nil
    @Published var selectedMarket: BoardMarket = .k
    @Published var selectedGameMarket: BoardMarket = .nrfi

    /// How long to wait between re-fetches while any market is still empty for
    /// today. Matches web Board polling (~90s). While markets are `[]`, each
    /// poll uses `&refresh=1` to force server-side recompute (iOS has no local
    /// `computeBatterBoard` fallback like the web client).
    private static let pollIntervalNanos: UInt64 = 90 * 1_000_000_000

    private var slateDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: Date())
    }

    var generatedAtLabel: String {
        guard let raw = snapshot?.generatedAt,
              let date = ISO8601DateFormatter().date(from: raw) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d 'at' h:mm a"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: date) + " HI"
    }

    // Current candidates based on selected tab
    var currentCandidates: [BoardCandidate] {
        let market = selectedMarket == .nrfi ? selectedGameMarket : selectedMarket
        return snapshot?.candidates(for: market) ?? []
    }

    /// Returns (hits, gradedTotal) for a given market tab, using boxscore or linescore data.
    func hitStats(for market: BoardMarket) -> (hits: Int, total: Int) {
        let candidates = snapshot?.candidates(for: market) ?? []
        var hits = 0
        var graded = 0

        let gameMarkets = ["nrfi", "total", "ml", "spread", "f5ml", "f5spread"]
        let isGameMarket = gameMarkets.contains(market.rawValue.lowercased())

        for candidate in candidates {
            if isGameMarket {
                // Handle game markets
                guard let gamePk = candidate.gamePk else { continue }
                let marketLower = market.rawValue.lowercased()

                // Check if game is final
                let isF5Market = ["f5ml", "f5spread"].contains(marketLower)
                if isF5Market {
                    // F5 markets need boxscore innings data
                    guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { continue }
                    guard innings.count >= 5 else { continue }  // Need at least 5 innings
                } else {
                    // Other game markets need linescore and game must be final
                    guard let linescore = GameResultManager.shared.linescore(for: gamePk) else { continue }
                    guard let inning = linescore.inning, inning >= 9 else { continue }  // Only count final games
                }

                graded += 1
                let outcome = calculateGameOutcome(for: candidate)
                if outcome == .hit {
                    hits += 1
                }
            } else {
                // Handle player-prop markets
                guard let playerId = candidate.rawId else { continue }
                guard let result = BoxscoreManager.shared.result(for: playerId) else { continue }
                guard !result.live else { continue }  // Only count final results

                graded += 1

                // Calculate outcome based on market type
                let didHit = calculateHit(candidate: candidate, result: result, market: market)
                if didHit {
                    hits += 1
                }
            }
        }

        return (hits, graded)
    }

    /// Calculate if a pick hit based on market type and boxscore data
    private func calculateHit(candidate: BoardCandidate, result: PlayerResult, market: BoardMarket) -> Bool {
        switch market {
        case .hr:
            return (result.ab ?? 0) > 0 && (result.hr ?? 0) > 0

        case .hits:
            let hasHR = (result.ab ?? 0) > 0 && (result.hr ?? 0) > 0
            let hasHit = (result.ab ?? 0) > 0 && (result.h ?? 0) > 0 && !hasHR
            return hasHR || hasHit

        case .k:
            guard let k = result.k, let line = candidate.bookLine else { return false }
            let isUnder = candidate.lean?.uppercased() == "UNDER"
            return isUnder ? Double(k) < line : Double(k) > line

        case .outs:
            guard let outs = result.outs, let line = candidate.bookLine else { return false }
            let isUnder = candidate.lean?.uppercased() == "UNDER"
            return isUnder ? Double(outs) < line : Double(outs) > line

        case .nrfi:
            guard let linescore = GameResultManager.shared.linescore(for: candidate.gamePk ?? 0) else { return false }
            guard let f1Away = linescore.firstInning?.away, let f1Home = linescore.firstInning?.home else { return false }
            let wasNRFI = f1Away == 0 && f1Home == 0
            let lean = candidate.lean?.uppercased() ?? "NRFI"
            return lean == "NRFI" ? wasNRFI : !wasNRFI

        case .total:
            guard let linescore = GameResultManager.shared.linescore(for: candidate.gamePk ?? 0) else { return false }
            guard let away = linescore.awayScore, let home = linescore.homeScore else { return false }
            guard let line = candidate.bookLine else { return false }
            let isUnder = candidate.lean?.uppercased() == "UNDER"
            let total = Double(away + home)
            return isUnder ? total < line : total > line

        case .ml, .spread, .f5ml, .f5spread:
            // Game outcome markets not yet supported in calculateHit (use calculateGameOutcome instead)
            return false
        }
    }

    /// True when the snapshot has been checked and this market is present
    /// but empty (`[]`) — i.e. "lineups not posted yet" rather than "no data
    /// fetched at all".
    func isEmptyButChecked(_ market: BoardMarket) -> Bool {
        snapshot?.rawArray(for: market)?.isEmpty == true
    }

    /// True only when the snapshot is for *today* and at least one of the
    /// 10 board markets is present-but-empty (`[]`) — meaning the backend
    /// may self-heal it on a follow-up request. Historical-date snapshots
    /// (or a snapshot we haven't loaded yet) never poll.
    private var shouldKeepPolling: Bool {
        guard let snapshot, snapshot.date == slateDate else { return false }
        return BoardMarket.allCases.contains { isEmptyButChecked($0) }
    }

    // MARK: - Fetch
    func load(refresh: Bool = false) async {
        DispatchQueue.main.async {
            if refresh { self.isRefreshing = true } else { self.isLoading = true }
            self.errorMessage = nil
        }
        do {
            var path = "\(Endpoints.boardSnapshot)?date=\(slateDate)"
            if refresh { path += "&refresh=1" }
            async let snapshotTask: BoardSnapshot = APIClient.shared.get(path: path)
            async let slateBundleTask: SlateBundle = APIClient.shared.get(
                path: "\(Endpoints.slateBundle)?date=\(slateDate)"
            )

            let (snap, bundle) = try await (snapshotTask, slateBundleTask)
            #if DEBUG
            if refresh {
                await Self.diagnoseHitsAndHR(path: path, decoded: snap)
            }
            #endif

            let oddsByGamePk = Self.buildOddsByGamePk(from: bundle)

            // Fetch boxscores and linescores for live/started games
            for game in bundle.schedule {
                if game.isLive || game.isFinal || !game.isUpcoming {
                    await BoxscoreManager.shared.fetchBoxscore(gamePk: game.gamePk, isFinal: game.isFinal)
                    await GameResultManager.shared.fetchLinescore(gamePk: game.gamePk, isFinal: game.isFinal)
                }
            }

            DispatchQueue.main.async {
                self.snapshot = snap
                self.slateOddsByGamePk = oddsByGamePk
                self.isLoading = false
                self.isRefreshing = false
            }
        } catch let e as APIError {
            DispatchQueue.main.async {
                self.errorMessage = e.errorDescription
                self.isLoading = false
                self.isRefreshing = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                self.isRefreshing = false
            }
        }
    }

    /// Initial load, then — if any market is present-but-empty (`[]`) for
    /// today — an immediate `&refresh=1` recompute plus periodic refresh
    /// polls every 90s (mirrors web `refreshBoardSnapshot` + empty-market
    /// polling). Stops when the view task is cancelled, all markets have
    /// data, or the snapshot date is no longer today.
    func loadAndPollIfNeeded() async {
        await load()
        if shouldKeepPolling {
            await load(refresh: true)
        }
        while !Task.isCancelled && shouldKeepPolling {
            do {
                try await Task.sleep(nanoseconds: Self.pollIntervalNanos)
            } catch {
                break
            }
            if Task.isCancelled { break }
            await load(refresh: true)
        }
    }

    func fallbackOdds(for gamePk: Int?) -> OddsData? {
        guard let gamePk else { return nil }
        return slateOddsByGamePk[gamePk]
    }

    // MARK: - Game market outcome helpers
    func calculateGameOutcome(for candidate: BoardCandidate) -> BadgeOutcome {
        let marketLower = candidate.market.lowercased()

        // Handle F5 markets first (they need boxscore, not linescore)
        if marketLower == "f5ml" {
            return calculateF5MLOutcome(candidate: candidate)
        }
        if marketLower == "f5spread" || marketLower == "f5rl" {
            return calculateF5RLOutcome(candidate: candidate)
        }

        guard let gamePk = candidate.gamePk else { return .pending }
        guard let linescore = GameResultManager.shared.linescore(for: gamePk) else { return .pending }

        switch marketLower {
        case "nrfi":
            return calculateNRFIOutcome(candidate: candidate, linescore: linescore)

        case "total":
            guard let inning = linescore.inning, inning >= 9 else { return .pending }  // Game must be finished
            return calculateTotalOutcome(candidate: candidate, linescore: linescore)

        case "ml":
            guard let inning = linescore.inning, inning >= 9 else { return .pending }
            return calculateMLOutcome(candidate: candidate, linescore: linescore)

        case "spread", "rl":
            guard let inning = linescore.inning, inning >= 9 else { return .pending }
            return calculateSpreadOutcome(candidate: candidate, linescore: linescore)

        default:
            return .pending
        }
    }

    private func calculateNRFIOutcome(candidate: BoardCandidate, linescore: LinescoreResponse) -> BadgeOutcome {
        guard let f1Away = linescore.firstInning?.away, let f1Home = linescore.firstInning?.home else { return .pending }
        let wasNRFI = f1Away == 0 && f1Home == 0
        let lean = candidate.lean?.uppercased() ?? "NRFI"
        let hit = lean == "NRFI" ? wasNRFI : !wasNRFI
        return hit ? .hit : .miss
    }

    private func calculateTotalOutcome(candidate: BoardCandidate, linescore: LinescoreResponse) -> BadgeOutcome {
        guard let away = linescore.awayScore, let home = linescore.homeScore else { return .pending }
        guard let line = candidate.bookLine else { return .pending }
        let total = Double(away + home)
        let isUnder = candidate.lean?.uppercased() == "UNDER"
        let hit = isUnder ? total < line : total > line
        return hit ? .hit : .miss
    }

    private func calculateMLOutcome(candidate: BoardCandidate, linescore: LinescoreResponse) -> BadgeOutcome {
        guard let away = linescore.awayScore, let home = linescore.homeScore else { return .pending }
        if away == home { return .pending }  // Tie
        let lean = candidate.lean?.uppercased() ?? "HOME"
        let hit = lean == "HOME" ? home > away : away > home
        return hit ? .hit : .miss
    }

    private func calculateSpreadOutcome(candidate: BoardCandidate, linescore: LinescoreResponse) -> BadgeOutcome {
        guard let away = linescore.awayScore, let home = linescore.homeScore else { return .pending }
        guard let line = candidate.bookLine else { return .pending }
        let lean = candidate.lean?.uppercased() ?? "HOME"
        let awayDouble = Double(away)
        let homeDouble = Double(home)
        let hit = lean == "HOME" ? (homeDouble + line) > awayDouble : (awayDouble + line) > homeDouble
        return hit ? .hit : .miss
    }

    private func calculateF5MLOutcome(candidate: BoardCandidate) -> BadgeOutcome {
        guard let gamePk = candidate.gamePk else { return .pending }
        guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { return .pending }
        guard innings.count >= 5 else { return .pending }

        let f5Away = innings[0..<5].reduce(0) { $0 + ($1.away ?? 0) }
        let f5Home = innings[0..<5].reduce(0) { $0 + ($1.home ?? 0) }

        if f5Away == f5Home { return .pending }  // F5 tie = push, no result

        let lean = candidate.lean?.uppercased() ?? "HOME"
        let hit = lean == "HOME" ? f5Home > f5Away : f5Away > f5Home
        return hit ? .hit : .miss
    }

    private func calculateF5RLOutcome(candidate: BoardCandidate) -> BadgeOutcome {
        guard let gamePk = candidate.gamePk else { return .pending }
        guard let innings = BoxscoreManager.shared.innings(for: gamePk) else { return .pending }
        guard innings.count >= 5 else { return .pending }
        guard let line = candidate.bookLine else { return .pending }

        let f5Away = Double(innings[0..<5].reduce(0) { $0 + ($1.away ?? 0) })
        let f5Home = Double(innings[0..<5].reduce(0) { $0 + ($1.home ?? 0) })

        let lean = candidate.lean?.uppercased() ?? "HOME"
        let hit = lean == "HOME" ? (f5Home + line) > f5Away : (f5Away + line) > f5Home
        return hit ? .hit : .miss
    }

    private static func buildOddsByGamePk(from bundle: SlateBundle) -> [Int: OddsData] {
        var result: [Int: OddsData] = [:]
        for game in bundle.schedule {
            guard let odds = bundle.oddsMap?[game.oddsKey] ?? nil else { continue }
            result[game.gamePk] = odds
        }
        return result
    }

    #if DEBUG
    /// One-shot diagnostic: re-fetches the same path as raw JSON (bypassing
    /// `LossyArray`) and reports, for `hr`/`hits`, the raw element count vs.
    /// the count `BoardSnapshot` actually decoded, the `date` field as
    /// returned by the server, and — if there's a raw/decoded count mismatch
    /// — the keys and decode error for the first raw element. This isolates
    /// whether HR/Hits candidates are present in the response but being
    /// silently dropped by `LossyArray` due to a field shape mismatch.
    private static func diagnoseHitsAndHR(path: String, decoded: BoardSnapshot) async {
        do {
            let raw = try await APIClient.shared.getRawData(path: path)
            guard let json = try JSONSerialization.jsonObject(with: raw) as? [String: Any] else {
                print("📦 board/snapshot diagnostic: top-level JSON is not an object")
                return
            }
            print("📦 board/snapshot date field = \(String(describing: json["date"]))")
            for key in ["hr", "hits"] {
                let rawArr = json[key] as? [[String: Any]]
                let rawCount = rawArr?.count ?? -1
                let decodedCount = (key == "hr" ? decoded.hr : decoded.hits)?.count ?? -1
                print("📦 board/snapshot[\(key)] raw count = \(rawCount), decoded count = \(decodedCount)")
                if rawCount != decodedCount, let first = rawArr?.first {
                    let sortedKeys = first.keys.sorted()
                    print("📦 board/snapshot[\(key)] first raw element keys = \(sortedKeys)")
                    if let elementData = try? JSONSerialization.data(withJSONObject: first) {
                        do {
                            _ = try JSONDecoder().decode(BoardCandidate.self, from: elementData)
                            print("✅ board/snapshot[\(key)] first element decodes as BoardCandidate (unexpected given count mismatch)")
                        } catch {
                            print("❌ board/snapshot[\(key)] first element decode error: \(error)")
                        }
                    }
                }
            }
        } catch {
            print("⚠️ board/snapshot diagnostic raw fetch failed: \(error)")
        }
    }

    #endif
}
