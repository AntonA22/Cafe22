//
//  APIClient.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private let baseURL = "https://anton.panfilius.ru/api"
    private let session: URLSession = .shared
    private var tokenStorage: TokenStorageProtocol = KeychainTokenStorage.shared

    func request<T: Decodable>(
        path: String,
        method: String,
        body: Encodable? = nil,
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

            if (200...299).contains(status) {
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decoding(error)
                }
            }

            if status == 422, let errors = parseLaravelErrors(from: data) {
                throw APIError.validation(errors)
            }

            let message = parseLaravelMessage(from: data) ?? String(data: data, encoding: .utf8)
            throw APIError.badStatus(status, message: message)

        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.network(error)
        }
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
