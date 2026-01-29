import Foundation

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

struct SearchDTO: Encodable {
    let query: String
}

final class ProductsService {
    static let shared = ProductsService()
    private init() {}

    private let api = APIClient.shared

    func fetchProducts() async throws -> [Product] {
        try await api.request("/products", method: "GET")
    }

    func fetchProduct(id: Int) async throws -> Product {
        let wrapped: DataWrapper<Product> = try await api.request("/product/\(id)", method: "GET")
        return wrapped.data
    }
    
    func searchProducts(body: SearchDTO) async throws -> [Product] {
        try await api.request(
            "/products/search",
            method: "POST",
            body: body
        )
    }
}
