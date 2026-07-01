import Foundation

final class BoxscoreManager {
    static let shared = BoxscoreManager()

    private var cache: [Int: PlayerResult] = [:]  // playerId → result
    private var inningsCache: [Int: [InningScore]] = [:]  // gamePk → innings array
    private var lastFetchedGames: Set<Int> = []
    private var pollingTasks: [Int: Task<Void, Never>] = [:]

    /// Fetch boxscore for a game and cache results
    func fetchBoxscore(gamePk: Int, isFinal: Bool) async {
        // Skip if already fetched or polling
        if lastFetchedGames.contains(gamePk) {
            return
        }

        do {
            let boxscore: GameBoxscore = try await APIClient.shared.get(
                path: "/api/boxscore/\(gamePk)"
            )

            // Build results dict
            var newResults: [Int: PlayerResult] = [:]

            // Batting results
            if let batting = boxscore.batting {
                for batter in (batting.away ?? []) + (batting.home ?? []) {
                    newResults[batter.id] = PlayerResult(
                        h: batter.h,
                        hr: batter.hr,
                        ab: batter.ab,
                        k: nil,
                        outs: nil,
                        live: !isFinal
                    )
                }
            }

            // Pitching results
            if let pitching = boxscore.pitching {
                for pitcher in (pitching.away ?? []) + (pitching.home ?? []) {
                    newResults[pitcher.id] = PlayerResult(
                        h: nil,
                        hr: nil,
                        ab: nil,
                        k: pitcher.k,
                        outs: pitcher.outs,
                        live: !isFinal
                    )
                }
            }

            // Cache innings data for F5 calculations
            if let inningsArray = boxscore.linescore?.innings, !inningsArray.isEmpty {
                DispatchQueue.main.async {
                    self.inningsCache[gamePk] = inningsArray
                }
            }

            // Update cache
            DispatchQueue.main.async {
                self.cache.merge(newResults) { _, new in new }
                self.lastFetchedGames.insert(gamePk)
            }

            // If game is live (not final), poll every 60 seconds
            if !isFinal {
                startPolling(gamePk: gamePk)
            }
        } catch {
            // Silently fail — boxscore not yet available
        }
    }

    /// Get cached result for a player
    func result(for playerId: Int) -> PlayerResult? {
        cache[playerId]
    }

    /// Get cached innings array for a game (for F5 calculations)
    func innings(for gamePk: Int) -> [InningScore]? {
        inningsCache[gamePk]
    }

    /// Clear cache (e.g., on new day)
    func clearCache() {
        DispatchQueue.main.async {
            self.cache.removeAll()
            self.inningsCache.removeAll()
            self.lastFetchedGames.removeAll()
            self.pollingTasks.values.forEach { $0.cancel() }
            self.pollingTasks.removeAll()
        }
    }

    // MARK: - Polling for live games
    private func startPolling(gamePk: Int) {
        // Cancel any existing polling task
        pollingTasks[gamePk]?.cancel()

        let task = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 60 * 1_000_000_000)  // 60 seconds
                    if !Task.isCancelled {
                        await fetchBoxscore(gamePk: gamePk, isFinal: false)
                    }
                } catch {
                    break
                }
            }
        }

        pollingTasks[gamePk] = task
    }
}
