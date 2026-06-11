import Foundation
import Combine

final class AIBoardViewModel: ObservableObject {
    @Published var edges: [AIBoardEdge] = []
    @Published var generatedAt: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var selectedFilter: AIBoardFilter = .all

    var filteredEdges: [AIBoardEdge] {
        edges
            .filter { selectedFilter.matches($0) }
            .sorted { $0.aiScore > $1.aiScore }
    }

    var hitCount: Int  { edges.filter { $0.isHit  }.count }
    var missCount: Int { edges.filter { $0.isMiss }.count }

    /// Returns (hits, gradedTotal) for the given market filter tab.
    func hitStats(for filter: AIBoardFilter) -> (hits: Int, total: Int) {
        let graded = edges.filter { filter.matches($0) && ($0.isHit || $0.isMiss) }
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
