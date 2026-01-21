//
//  ProductDetailService.swift
//  Cafe
//
//  Created by Антон Абалуев on 03.01.2026.
//

import Foundation

struct ProductDetailResponse: Codable {
    let success: Bool
    let data: Product?
    let error: String?
}

enum ProductDetailError: LocalizedError {
    case invalidURL
    case badStatus(Int, String?)
    case apiError(String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .badStatus(let code, let body):
            return body ?? "Ошибка сервера (\(code))"
        case .apiError(let msg):
            return msg
        case .decoding:
            return "Ошибка обработки данных"
        }
    }
}

final class ProductDetailService {

    static let shared = ProductDetailService()
    private init() {}

    private let baseURL = "https://anton.panfilius.ru/api"

    func fetchProduct(id: Int) async throws -> Product {
        guard let url = URL(string: "\(baseURL)/product/\(id)") else {
            throw ProductDetailError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8)
            throw ProductDetailError.badStatus(status, body)
        }

        do {
            let decoded = try JSONDecoder().decode(ProductDetailResponse.self, from: data)

            guard decoded.success else {
                throw ProductDetailError.apiError(decoded.error ?? "Unknown error")
            }

            guard let product = decoded.data else {
                throw ProductDetailError.apiError("Товар не найден")
            }

            return product
        } catch {
            throw ProductDetailError.decoding(error)
        }
    }
}
