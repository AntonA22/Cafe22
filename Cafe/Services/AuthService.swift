import Foundation
import FirebaseMessaging

struct LoginDTO: Encodable { let login: String; let password: String }
struct ForgotPasswordDTO: Encodable { let email: String }
struct MessageDTO: Decodable { let message: String? }
struct ChangePasswordDTO: Encodable {
    let new_password: String
    let new_password_confirmation: String
}


struct RegisterDTO: Encodable {
    let username: String
    let email: String
    let phone: String?
    let first_name: String?
    let last_name: String?
    let password: String
    let password_confirmation: String
}
struct AuthResponseDTO: Decodable {
    let token: String
    let user: UserDTO
}

final class AuthService {
    static let shared = AuthService()
    private init() {}

    private let api = APIClient.shared
    private var tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared
    private(set) var currentUser: UserDTO?

    func login(login: String, password: String) async throws {
        let resp: AuthResponseDTO = try await api.request(
            "/auth/login",
            method: "POST",
            body: LoginDTO(login: login, password: password),
            authorized: false
        )
        tokenStorage.token = resp.token
        currentUser = resp.user
        await uploadFcmTokenIfAvailable()
    }

    func register(
        username: String,
        email: String,
        phone: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        password: String,
        passwordConfirmation: String
    ) async throws {

        let resp: AuthResponseDTO = try await api.request(
            "/auth/register",
            method: "POST",
            body: RegisterDTO(
                username: username,
                email: email,
                phone: phone,
                first_name: firstName,
                last_name: lastName,
                password: password,
                password_confirmation: passwordConfirmation
            ),
            authorized: false
        )

        tokenStorage.token = resp.token
        currentUser = resp.user
        await uploadFcmTokenIfAvailable()
    }

    func logout() {
        tokenStorage.clear()
        currentUser = nil
    }

    func forgotPassword(email: String) async throws {
        let _: MessageDTO = try await api.request(
            "/auth/forgot-password",
            method: "POST",
            body: ForgotPasswordDTO(email: email),
            authorized: false
        )
    }

    func changePassword(newPassword: String, confirmPassword: String) async throws {
        struct Empty: Decodable {}

        let _: Empty = try await api.request(
            "/me/password",
            method: "PUT",
            body: ChangePasswordDTO(
                new_password: newPassword,
                new_password_confirmation: confirmPassword
            ),
            authorized: true
        )

        tokenStorage.clear()
        currentUser = nil
    }

    func fetchMe() async throws -> UserDTO {
        let me: UserDTO = try await api.request("/me", method: "GET", authorized: true)
        currentUser = me
        return me
    }
    
    func updateMe(_ dto: UpdateProfileDTO) async throws -> UserDTO {
        let wrapped: DataWrapper<UserDTO> = try await api.request(
            "/me/update",
            method: "PUT",
            body: dto,
            authorized: true
        )
        return wrapped.data
    }
    
    func currentToken() -> String? {
        tokenStorage.token
    }

    private func uploadFcmTokenIfAvailable() async {
        guard let fcmToken = Messaging.messaging().fcmToken else { return }
        try? await sendFcmToken(fcmToken)
    }

    func sendFcmToken(_ fcmToken: String) async throws {
        struct FcmTokenDTO: Encodable { let fcm_token: String }
        struct Empty: Decodable {}
        let _: Empty = try await api.request(
            "/me/fcm-token",
            method: "POST",
            body: FcmTokenDTO(fcm_token: fcmToken),
            authorized: true
        )
    }
}
