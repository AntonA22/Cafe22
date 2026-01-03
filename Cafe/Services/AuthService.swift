import Foundation

struct LoginDTO: Encodable {
    let login: String
    let password: String
}

struct AuthResponseDTO: Decodable {
    let token: String
    // если хочешь — добавь user: UserDTO
}

final class TokenStorage {
    static let shared = TokenStorage()
    private init() {}

    private let key = "auth_token"

    var token: String? {
        get { UserDefaults.standard.string(forKey: key) }
        set { UserDefaults.standard.setValue(newValue, forKey: key) }
    }
}

enum APIError: Error {
    case invalidURL
    case badStatus(Int, String?)
    case decoding(Error)
    case network(Error)
}

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let baseURL = "http://127.0.0.1:8000/api"

    func login(login: String, password: String) async throws {
        guard let url = URL(string: "\(baseURL)/auth/login") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(LoginDTO(login: login, password: password))

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            guard (200...299).contains(status) else {
                let body = String(data: data, encoding: .utf8)
                throw APIError.badStatus(status, body)
            }

            do {
                let auth = try JSONDecoder().decode(AuthResponseDTO.self, from: data)
                TokenStorage.shared.token = auth.token
            } catch {
                throw APIError.decoding(error)
            }
        } catch {
            throw APIError.network(error)
        }
    }
}
