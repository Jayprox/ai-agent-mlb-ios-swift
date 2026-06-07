import Foundation
import Combine
import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    init() {
        isAuthenticated = KeychainManager.loadToken() != nil
    }

    // MARK: - Login
    func login(username: String, password: String) async {
        guard !username.isEmpty, !password.isEmpty else {
            await setError("Please enter your username and password.")
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        do {
            let response: LoginResponse = try await APIClient.shared.post(
                path: Endpoints.login,
                body: LoginRequest(username: username, password: password),
                authenticated: false
            )
            KeychainManager.saveToken(response.token)
            DispatchQueue.main.async {
                self.username = response.username
                self.isLoading = false
                self.isAuthenticated = true
            }
        } catch let error as APIError {
            await setError(error.errorDescription ?? "Login failed.")
        } catch {
            await setError(error.localizedDescription)
        }
    }

    // MARK: - Sign out
    func signOut() {
        Task {
            let _: OkResponse? = try? await APIClient.shared.post(
                path: Endpoints.logout,
                body: EmptyBody(),
                authenticated: true
            )
        }
        KeychainManager.deleteToken()
        DispatchQueue.main.async {
            self.username = ""
            self.isAuthenticated = false
        }
    }

    // MARK: - Helpers
    @MainActor
    private func setError(_ message: String) {
        errorMessage = message
        isLoading = false
    }
}

private struct EmptyBody: Encodable {}
