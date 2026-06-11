import Foundation
import Combine

final class PredictViewModel: ObservableObject {
    @Published var edges: [AIBoardEdge] = []
    @Published var generatedAt: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    /// Player-prop edges where simulated probability exceeds book implied probability,
    /// sorted by edge (descending).
    var predictPicks: [AIBoardEdge] {
        edges
            .filter { $0.isPredictPick }
            .sorted { ($0.edgePts ?? 0) > ($1.edgePts ?? 0) }
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
