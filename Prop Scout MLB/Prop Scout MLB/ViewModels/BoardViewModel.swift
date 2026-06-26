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

    /// Returns (hits, gradedTotal) for a given market tab.
    func hitStats(for market: BoardMarket) -> (hits: Int, total: Int) {
        let candidates = snapshot?.candidates(for: market) ?? []
        let graded = candidates.filter { $0.gradeIsHit != nil }
        return (graded.filter { $0.gradeIsHit == true }.count, graded.count)
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
