import Foundation

struct LoginRequest: Encodable {
    let username: String
    let password: String
}

struct LoginResponse: Decodable {
    let token: String
    let userId: IntOrString
    let username: String
    let role: String?
}

// Handles userId coming back as either Int or String
enum IntOrString: Decodable {
    case int(Int), string(String)
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self)    { self = .int(i);    return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        throw DecodingError.typeMismatch(IntOrString.self, .init(codingPath: decoder.codingPath, debugDescription: "Expected Int or String"))
    }
}

struct MeResponse: Decodable {
    let userId: String
    let username: String
    let role: String?
}

struct OkResponse: Decodable {
    let ok: Bool
}

// MARK: - Preferences
struct PreferencesResponse: Decodable {
    let preferences: Preferences
}

struct Preferences: Decodable {
    let preferredBook: String?
}

struct PreferencesUpdateRequest: Encodable {
    let preferredBook: String?
}
