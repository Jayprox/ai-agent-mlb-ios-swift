import Foundation
import Combine

final class LeaderboardViewModel: ObservableObject {
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var userStats: UserLeaderboardStats?
    @Published var sortBy: LeaderboardSortBy = .winRate
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isOptingIn = false

    private let limit = 100
    private var offset = 0

    // MARK: - Fetch Leaderboard
    func loadLeaderboard() async {
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let path = "\(Endpoints.leaderboard)?sortBy=\(sortBy.rawValue)&limit=\(limit)&offset=\(offset)"
            let response: LeaderboardResponse = try await APIClient.shared.get(path: path, authenticated: false)

            if response.unavailable == true {
                throw APIError.serverError(503, "Leaderboard temporarily unavailable")
            }

            DispatchQueue.main.async {
                self.leaderboard = response.leaderboard
                self.isLoading = false
            }
        } catch let e as APIError {
            DispatchQueue.main.async {
                self.errorMessage = e.errorDescription
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    // MARK: - Fetch User Stats
    func loadUserStats() async {
        do {
            let response: UserLeaderboardStats = try await APIClient.shared.get(
                path: "\(Endpoints.leaderboard)/me"
            )
            DispatchQueue.main.async {
                self.userStats = response
            }
        } catch {
            // User stats are not critical; silently fail
        }
    }

    // MARK: - Opt-in
    func optInToLeaderboard(username: String) async -> Bool {
        DispatchQueue.main.async {
            self.isOptingIn = true
            self.errorMessage = nil
        }

        do {
            let request = LeaderboardOptInRequest(username: username)
            let response: LeaderboardOptInResponse = try await APIClient.shared.post(
                path: "\(Endpoints.leaderboard)/opt-in",
                body: request
            )

            if response.ok {
                DispatchQueue.main.async {
                    self.isOptingIn = false
                    // Refresh user stats after opting in
                    Task {
                        await self.loadUserStats()
                        await self.loadLeaderboard()
                    }
                }
                return true
            }
            return false
        } catch let e as APIError {
            DispatchQueue.main.async {
                self.errorMessage = e.errorDescription
                self.isOptingIn = false
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isOptingIn = false
            }
            return false
        }
    }

    // MARK: - Opt-out
    func optOutOfLeaderboard() async -> Bool {
        do {
            let response: LeaderboardOptOutResponse = try await APIClient.shared.post(
                path: "\(Endpoints.leaderboard)/opt-out",
                body: [String: String]()
            )

            if response.ok {
                DispatchQueue.main.async {
                    // Refresh user stats after opting out
                    Task {
                        await self.loadUserStats()
                        await self.loadLeaderboard()
                    }
                }
                return true
            }
            return false
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    // MARK: - Change Sort
    func changeSortBy(_ newSort: LeaderboardSortBy) async {
        DispatchQueue.main.async {
            self.sortBy = newSort
            self.offset = 0
        }
        await loadLeaderboard()
    }

    // MARK: - Load More
    func loadMore() async {
        offset += limit
        await loadLeaderboard()
    }

    // MARK: - Refresh
    func refresh() async {
        offset = 0
        await loadLeaderboard()
        if KeychainManager.loadToken() != nil {
            await loadUserStats()
        }
    }
}
