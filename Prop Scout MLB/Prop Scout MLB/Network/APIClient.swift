import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int, String?)
    case decodingError(Error)
    case networkError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .unauthorized:
            return "Session expired. Please log in again."
        case .serverError(let code, let msg):
            return msg ?? "Server error (\(code))."
        case .decodingError(let e):
            return "Data error: \(e.localizedDescription)"
        case .networkError(let e):
            return e.localizedDescription
        case .unknown:
            return "An unknown error occurred."
        }
    }
}

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let session = URLSession.shared

    // MARK: - Core request (body pre-serialized to Data)
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        bodyData: Data? = nil,
        authenticated: Bool = true
    ) async throws -> T {
        guard let url = URL(string: Endpoints.baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authenticated, let token = KeychainManager.loadToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        req.httpBody = bodyData

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.unknown }

        switch http.statusCode {
        case 200...299:
            break
        case 401:
            KeychainManager.deleteToken()
            throw APIError.unauthorized
        default:
            let msg = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            throw APIError.serverError(http.statusCode, msg?.error)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Convenience wrappers
    func get<T: Decodable>(path: String, authenticated: Bool = true) async throws -> T {
        try await request(path: path, method: "GET", authenticated: authenticated)
    }

    func post<T: Decodable, B: Encodable>(
        path: String,
        body: B,
        authenticated: Bool = true
    ) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: "POST", bodyData: data, authenticated: authenticated)
    }

    func patch<T: Decodable, B: Encodable>(path: String, body: B) async throws -> T {
        let data = try JSONEncoder().encode(body)
        return try await request(path: path, method: "PATCH", bodyData: data)
    }
}

private struct ErrorResponse: Decodable {
    let error: String?
}
