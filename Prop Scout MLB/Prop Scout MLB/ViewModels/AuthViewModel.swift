import Foundation
import Combine
import SwiftUI

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var username: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    /// Preferred sportsbook — synced with backend (/api/auth/preferences),
    /// cached locally so the UI has a value before the network round trip.
    @Published var preferredBook: String = UserDefaults.standard.string(forKey: "preferredBook") ?? "DK"

    init() {
        isAuthenticated = KeychainManager.loadToken() != nil
        if isAuthenticated {
            Task {
                await restoreUsername()
                await loadPreferences()
            }
        }
    }

    // MARK: - Restore username from token
    private func restoreUsername() async {
        do {
            let me: MeResponse = try await APIClient.shared.get(path: Endpoints.me)
            DispatchQueue.main.async { self.username = me.username }
        } catch {
            // Token invalid — sign out silently
            if case APIError.unauthorized = error {
                DispatchQueue.main.async { self.isAuthenticated = false }
            }
        }
    }

    // MARK: - Preferences
    func loadPreferences() async {
        guard let resp: PreferencesResponse = try? await APIClient.shared.get(path: Endpoints.preferences) else { return }
        if let book = resp.preferences.preferredBook {
            DispatchQueue.main.async {
                self.preferredBook = book
                UserDefaults.standard.set(book, forKey: "preferredBook")
            }
        }
    }

    func updatePreferredBook(_ book: String) async {
        DispatchQueue.main.async {
            self.preferredBook = book
            UserDefaults.standard.set(book, forKey: "preferredBook")
        }
        let _: PreferencesResponse? = try? await APIClient.shared.put(
            path: Endpoints.preferences,
            body: PreferencesUpdateRequest(preferredBook: book)
        )
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
            await loadPreferences()
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
