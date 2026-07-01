import Foundation

final class GameResultManager {
    static let shared = GameResultManager()

    private var cache: [Int: LinescoreResponse] = [:]  // gamePk → linescore
    private var pollingTasks: [Int: Task<Void, Never>] = [:]

    /// Fetch linescore for a live/final game
    func fetchLinescore(gamePk: Int, isFinal: Bool) async {
        do {
            let response: LinescoreResponse = try await APIClient.shared.get(
                path: "/api/linescore/\(gamePk)"
            )

            DispatchQueue.main.async {
                self.cache[gamePk] = response
            }

            // If game is live, poll every 60 seconds
            if !isFinal {
                startPolling(gamePk: gamePk)
            }
        } catch {
            // Silently fail — linescore not yet available
        }
    }

    /// Get cached linescore for a game
    func linescore(for gamePk: Int) -> LinescoreResponse? {
        cache[gamePk]
    }

    /// Clear cache
    func clearCache() {
        DispatchQueue.main.async {
            self.cache.removeAll()
            self.pollingTasks.values.forEach { $0.cancel() }
            self.pollingTasks.removeAll()
        }
    }

    // MARK: - Polling for live games

    private func startPolling(gamePk: Int) {
        pollingTasks[gamePk]?.cancel()

        let task = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: 60 * 1_000_000_000)  // 60 seconds
                    if !Task.isCancelled {
                        await fetchLinescore(gamePk: gamePk, isFinal: false)
                    }
                } catch {
                    break
                }
            }
        }

        pollingTasks[gamePk] = task
    }
}
