import Foundation
import Combine

/// Drives the "Model Picks" tab — reuses the AI Board edges feed, filtered to
/// player-prop edges that carry a verified market line, grouped by
/// simulation-confidence tier.
final class ModelPicksViewModel: ObservableObject {
    @Published var edges: [AIBoardEdge] = []
    @Published var generatedAt: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    /// All edges eligible for the Model Picks tab, sorted by simulation confidence.
    var modelPicks: [AIBoardEdge] {
        edges
            .filter { $0.isModelPick }
            .sorted { ($0.simConfidence ?? 0) > ($1.simConfidence ?? 0) }
    }

    func picks(for tier: ModelConfidenceTier) -> [AIBoardEdge] {
        modelPicks.filter { $0.confidenceTier == tier }
    }

    /// (hits, gradedTotal) across all model picks.
    var hitStats: (hits: Int, total: Int) {
        let graded = modelPicks.filter { $0.isHit || $0.isMiss }
        return (graded.filter { $0.isHit }.count, graded.count)
    }

    var generatedAtLabel: String {
        guard let raw = generatedAt,
              let date = ISO8601DateFormatter().date(from: raw) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d 'at' h:mm a"
        f.timeZone = TimeZone(identifier: "Pacific/Honolulu")
        return f.string(from: date) + " HI"
    }

    func load() async {
        DispatchQueue.main.async { self.isLoading = true; self.errorMessage = nil }
        do {
            let resp: AIBoardResponse = try await APIClient.shared.get(
                path: Endpoints.aiBoardEdges
            )
            DispatchQueue.main.async {
                self.edges       = resp.edges
                self.generatedAt = resp.generatedAt
                self.isLoading   = false
            }
        } catch let e as APIError {
            DispatchQueue.main.async { self.errorMessage = e.errorDescription; self.isLoading = false }
        } catch {
            DispatchQueue.main.async { self.errorMessage = error.localizedDescription; self.isLoading = false }
        }
    }
}
