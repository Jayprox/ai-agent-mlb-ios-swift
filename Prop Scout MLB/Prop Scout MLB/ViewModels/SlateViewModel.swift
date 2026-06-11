import Foundation
import Combine

final class SlateViewModel: ObservableObject {
    @Published var games: [SlateGame] = []
    @Published var oddsMap: [String: OddsData?] = [:]
    @Published var nrfiMap: [String: NRFIData?] = [:]
    @Published var weatherMap: [String: WeatherData?] = [:]
    @Published var kHintsMap: [String: String?] = [:]
    @Published var liveScores: [Int: LinescoreData] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var lastUpdated: Date? = nil

    /// Top model picks for the "Model Picks" preview card, by simulation confidence.
    @Published var topModelPicks: [AIBoardEdge] = []

    private var pollTimer: Timer?
    private var slateDate: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: Date())
    }

    // MARK: - Fetch slate bundle
    func load() async {
        DispatchQueue.main.async { self.isLoading = true; self.errorMessage = nil }
        do {
            let bundle: SlateBundle = try await APIClient.shared.get(
                path: "\(Endpoints.slateBundle)?date=\(slateDate)"
            )
            DispatchQueue.main.async {
                self.games       = bundle.schedule
                self.oddsMap     = bundle.oddsMap
                self.nrfiMap     = bundle.nrfiMap
                self.weatherMap  = bundle.weatherMap
                self.kHintsMap   = bundle.kHintsMap ?? [:]
                self.isLoading   = false
                self.lastUpdated = Date()
            }
            startPolling()
        } catch let e as APIError {
            DispatchQueue.main.async { self.errorMessage = e.errorDescription; self.isLoading = false }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }

        await loadModelPicksPreview()
    }

    /// Fetches the AI Board edges feed and surfaces the top 3 player-prop
    /// "Model Picks" by simulation confidence, for the Slate preview card.
    private func loadModelPicksPreview() async {
        do {
            let resp: AIBoardResponse = try await APIClient.shared.get(
                path: Endpoints.aiBoardEdges
            )
            let picks = resp.edges
                .filter { $0.isModelPick }
                .sorted { ($0.simConfidence ?? 0) > ($1.simConfidence ?? 0) }
            DispatchQueue.main.async {
                self.topModelPicks = Array(picks.prefix(3))
            }
        } catch {
            // Non-fatal — the preview card simply won't appear.
        }
    }

    // MARK: - Live score polling
    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { await self?.pollLiveGames() }
        }
        // Poll immediately on start
        Task { await pollLiveGames() }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func pollLiveGames() async {
        let liveGames = games.filter { $0.isLive || $0.isUpcoming || $0.isFinal }
        guard !liveGames.isEmpty else { return }

        await withTaskGroup(of: (Int, LinescoreData?).self) { group in
            for game in liveGames {
                group.addTask {
                    let score: LinescoreData? = try? await APIClient.shared.get(
                        path: Endpoints.linescore(gamePk: game.gamePk)
                    )
                    return (game.gamePk, score)
                }
            }
            var updated: [Int: LinescoreData] = [:]
            for await (pk, score) in group {
                if let score { updated[pk] = score }
            }
            DispatchQueue.main.async {
                for (pk, score) in updated {
                    self.liveScores[pk] = score
                }
                // Update game statuses from linescore
                self.games = self.games.map { game in
                    var g = game
                    return g
                }
            }
        }
    }

    // MARK: - Helpers
    func odds(for game: SlateGame) -> OddsData? {
        oddsMap[game.oddsKey] ?? nil
    }

    func nrfi(for game: SlateGame) -> NRFIData? {
        nrfiMap[String(game.gamePk)] ?? nil
    }

    func weather(for game: SlateGame) -> WeatherData? {
        weatherMap[String(game.gamePk)] ?? nil
    }

    func kHint(for game: SlateGame) -> String? {
        kHintsMap[String(game.gamePk)] ?? nil
    }

    func linescore(for game: SlateGame) -> LinescoreData? {
        liveScores[game.gamePk]
    }

    var liveCount: Int { games.filter { $0.isLive }.count }
    var gameCount: Int { games.count }
}
