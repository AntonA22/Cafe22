import Foundation
import Security

// MARK: - DTO

struct LoginDTO: Encodable {
    let login: String
    let password: String
}

struct RegisterDTO: Encodable {
    let username: String
    let email: String
    let phone: String?
    let first_name: String?
    let last_name: String?
    let password: String
}

struct AuthResponseDTO: Decodable {
    let token: String
}

// MARK: - Errors (Laravel-friendly)

enum APIError: LocalizedError {
    case invalidURL
    case badStatus(Int, message: String?)
    case validation([String: [String]])
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный адрес сервера"
        case .badStatus(let code, let message):
            return message ?? "Ошибка сервера (\(code))"
        case .validation(let errors):
            let text = errors.values.flatMap { $0 }.joined(separator: "\n")
            return text.isEmpty ? "Проверьте введённые данные" : text
        case .decoding:
            return "Не удалось обработать ответ сервера"
        case .network(let e):
            return e.localizedDescription
        }
    }
}

// MARK: - Token storage (Keychain)

protocol TokenStorageProtocol {
    var token: String? { get set }
    func clear()
}

final class KeychainTokenStorage: TokenStorageProtocol {
    static let shared = KeychainTokenStorage()
    private init() {}

    private let service = Bundle.main.bundleIdentifier ?? "default.service"
    private let account = "auth_token"

    var token: String? {
        get { read(account: account) }
        set {
            if let newValue {
                save(newValue, account: account)
            } else {
                delete(account: account)
            }
        }
    }

    func clear() {
        delete(account: account)
    }

    // MARK: Keychain helpers

    private func save(_ value: String, account: String) {
        let data = Data(value.utf8)

        // сначала удалим, потом добавим (так проще и надёжно)
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        SecItemAdd(query as CFDictionary, nil)
    }

    private func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8)
        else { return nil }

        return value
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - AuthService

final class AuthService {
    static let shared = AuthService()
    private init() {}

    // твой API base:
    private let baseURL = "https://anton.panfilius.ru/api"

    private let session: URLSession = .shared
    private var tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared

    // общий метод запроса
    private func performRequest<T: Decodable>(
        path: String,
        method: String = "POST",
        body: Encodable?,
        authorized: Bool = false
    ) async throws -> T {

        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if authorized, let token = tokenStorage.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        do {
            let (data, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1

            // успех
            if (200...299).contains(status) {
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decoding(error)
                }
            }

            // Laravel 422 (валидация)
            if status == 422,
               let errors = parseLaravelErrors(from: data) {
                throw APIError.validation(errors)
            }

            // прочие ошибки: попробуем вытащить message
            let message = parseLaravelMessage(from: data) ?? String(data: data, encoding: .utf8)
            throw APIError.badStatus(status, message: message)

        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error)
        }
    }

    // MARK: - Public API

    func login(login: String, password: String) async throws {
        // если на бекенде поле называется username/email — подстрой DTO/endpoint
        let auth: AuthResponseDTO = try await performRequest(
            path: "/auth/login",
            body: LoginDTO(login: login, password: password)
        )
        tokenStorage.token = auth.token
    }

    func register(
        username: String,
        email: String,
        phone: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        password: String
    ) async throws {

        let dto = RegisterDTO(
            username: username,
            email: email,
            phone: phone,
            first_name: firstName,
            last_name: lastName,
            password: password
        )

        // у тебя в Laravel: register(RegisterRequest...)
        // значит обычно это POST /register или /auth/register — поставь свой путь.
        let auth: AuthResponseDTO = try await performRequest(
            path: "/auth/register",
            body: dto
        )
        tokenStorage.token = auth.token
    }

    func logout() {
        tokenStorage.clear()
    }

    func currentToken() -> String? {
        tokenStorage.token
    }
}

struct DataWrapper<T: Decodable>: Decodable {
    let data: T
}

extension AuthService {

    func fetchMe() async throws -> UserDTO {
        let resp: DataWrapper<UserDTO> = try await performRequest(
            path: "/me",
            method: "GET",
            body: nil,
            authorized: true
        )
        return resp.data
    }
    
    func updateMe(_ dto: UpdateProfileDTO) async throws -> UserDTO {
        // твой роут: PUT /me/update
        // ответ: чаще всего {"data": {...}} (JsonResource)
        // если вдруг без data — ниже дам вариант
        let resp: DataWrapper<UserDTO> = try await performRequest(
            path: "/me/update",
            method: "PUT",
            body: dto,
            authorized: true
        )
        return resp.data
    }
}

// MARK: - Helpers

/// Чтобы кодировать Encodable без generic-танцев
private struct AnyEncodable: Encodable {
    private let encodeBlock: (Encoder) throws -> Void
    init(_ wrapped: Encodable) {
        self.encodeBlock = wrapped.encode
    }
    func encode(to encoder: Encoder) throws {
        try encodeBlock(encoder)
    }
}

private func parseLaravelMessage(from data: Data) -> String? {
    guard
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let msg = obj["message"] as? String
    else { return nil }
    return msg
}

private func parseLaravelErrors(from data: Data) -> [String: [String]]? {
    guard
        let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let errors = obj["errors"] as? [String: [String]]
    else { return nil }
    return errors
}

