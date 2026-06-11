import Foundation
import Combine

final class ScoutViewModel: ObservableObject {
    // MARK: - Inputs
    @Published var dailyGoal: Int = 50   // $25 / $50 / $75 / $100
    @Published var unitSize: Int = 25    // $10 / $25 / $50

    static let dailyGoalOptions = [25, 50, 75, 100]
    static let unitSizeOptions  = [10, 25, 50]

    /// Assumed hit rate baked into the EV model — matches the web app's "62.5%".
    static let assumedHitRate: Double = 0.625

    // MARK: - Slate state
    @Published var edges: [AIBoardEdge] = []
    @Published var slate: [AIBoardEdge] = []
    @Published var hasBuilt = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - Computed bankroll math
    var target: Int { dailyGoal }

    /// Expected value per unit at -110, given the assumed hit rate.
    private var evPerUnit: Double {
        let hr = Self.assumedHitRate
        let payoutMultiplier = 100.0 / 110.0 // -110 odds win payout per $1 risked
        return Double(unitSize) * (hr * payoutMultiplier - (1 - hr))
    }

    var unitsNeeded: Int {
        guard evPerUnit > 0 else { return 0 }
        return Int((Double(target) / evPerUnit).rounded(.up))
    }

    var riskEstimate: Int { unitsNeeded * unitSize }

    var assumedHitRateDisplay: String {
        let pct = Self.assumedHitRate * 100
        return pct == pct.rounded() ? "\(Int(pct))%" : String(format: "%.1f%%", pct)
    }

    // MARK: - Load edges
    func load() async {
        DispatchQueue.main.async { self.isLoading = true; self.errorMessage = nil }
        do {
            let resp: AIBoardResponse = try await APIClient.shared.get(
                path: Endpoints.aiBoardEdges
            )
            DispatchQueue.main.async {
                self.edges     = resp.edges
                self.isLoading = false
            }
        } catch let e as APIError {
            DispatchQueue.main.async { self.errorMessage = e.errorDescription; self.isLoading = false }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
    }

    // MARK: - Slate building

    /// Pool of candidate edges, strongest first.
    private var candidatePool: [AIBoardEdge] {
        edges
            .filter { $0.aiScore > 0 }
            .sorted { $0.aiScore > $1.aiScore }
    }

    /// Build a fresh slate from the top edges on the board, sized to the units needed.
    func buildSlate() {
        let pool = candidatePool
        let count = max(1, min(unitsNeeded, pool.count))
        slate = Array(pool.prefix(count))
        hasBuilt = true
    }

    /// Re-roll the slate, picking a different combination from a slightly wider pool.
    func regenerate() {
        let pool = candidatePool
        guard !pool.isEmpty else { slate = []; hasBuilt = true; return }
        let count = max(1, min(unitsNeeded, pool.count))
        let widePool = Array(pool.prefix(min(pool.count, count * 2)))
        slate = Array(widePool.shuffled().prefix(count))
        hasBuilt = true
    }
}
