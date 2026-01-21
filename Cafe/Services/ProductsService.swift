//
//  ProductsService.swift
//  Cafe
//
//  Created by Антон Абалуев on 03.01.2026.
//

import Foundation

struct ProductsResponse: Codable {
    let success: Bool
    let data: [Product]?
    let error: String?
}

struct Product: Codable {
    let id: Int
    let name: String
    let category: String?
    let description: String?
    let price: Double
    let photos: [String]?
    let available: Bool?
    let weight: Double?
    let calories: Int?
    let proteins: Double?
    let fats: Double?
    let carbohydrates: Double?
}

enum ProductsAPIError: LocalizedError {
    case invalidURL
    case badStatus(Int, String?)
    case apiError(String)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Неверный URL"
        case .badStatus(let code, let body): return body ?? "Ошибка сервера (\(code))"
        case .apiError(let msg): return msg
        case .decoding: return "Ошибка чтения данных"
        }
    }
}

final class ProductsService {
    static let shared = ProductsService()
    private init() {}

    // лучше держать /api отдельно, но оставлю как у тебя
//    private let urlString = "https://anton.panfilius.ru/products"
    private let urlString = "https://anton.panfilius.ru/api/products"

    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: urlString) else { throw ProductsAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard (200...299).contains(status) else {
            let body = String(data: data, encoding: .utf8)
            throw ProductsAPIError.badStatus(status, body)
        }

        do {
            let decoded = try JSONDecoder().decode(ProductsResponse.self, from: data)

            guard decoded.success else {
                throw ProductsAPIError.apiError(decoded.error ?? "Unknown API error")
            }

            return decoded.data ?? []
        } catch {
            throw ProductsAPIError.decoding(error)
        }
    }
}
