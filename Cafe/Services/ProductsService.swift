import Foundation

struct Product: Codable {
    let id: Int
    let name: String
    let category: String?
    let description: String?
    let composition: String?
    let price: Double
    let photos: [String]?
    let available: Bool?
    let weight: Double?
    let calories: Int?
    let proteins: Double?
    let fats: Double?
    let carbohydrates: Double?
    let isFavorite: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, category, description, composition, price, photos, available, weight, calories, proteins, fats, carbohydrates
        case isFavorite = "is_favorite"
    }
}

struct SearchDTO: Encodable {
    let query: String
}
  extension SearchDTO {
    func toQueryItems() -> [URLQueryItem] {
        return [URLQueryItem(name: "query", value: self.query)]
    }
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
       /* try await api.request(
            "/products/search",
            method: "GET",
            body: body
        )*/
         let urlString = "/products/search"
    var components = URLComponents(string: urlString)!
    components.queryItems = body.toQueryItems()
    
    return try await api.request(
        components.url?.absoluteString ?? "/products/search",
        method: "GET"
    )
    }
}

extension Notification.Name {
    static let favoritesDidChange = Notification.Name("favoritesDidChange")
}

final class FavoritesService {
    static let shared = FavoritesService()
    private init() {}

    private let api = APIClient.shared

    func fetchFavorites() async throws -> [Product] {
        try await api.request("/favorites", method: "GET", authorized: true)
    }

    func searchFavorites(query: String) async throws -> [Product] {
        var components = URLComponents(string: "/favorites/search")!
        components.queryItems = [URLQueryItem(name: "query", value: query)]

        return try await api.request(
            components.url?.absoluteString ?? "/favorites/search",
            method: "GET",
            authorized: true
        )
    }

    func fetchFavoriteIDs() async throws -> Set<Int> {
        let products = try await fetchFavorites()
        return Set(products.map(\.id))
    }

    func addFavorite(dessertId: Int) async throws {
        let response: FavoriteActionResponse = try await api.request(
            "/favorites/\(dessertId)",
            method: "POST",
            authorized: true
        )

        print("ADD FAVORITE RESPONSE:", response)
        notifyFavoritesChanged()
    }

    func removeFavorite(dessertId: Int) async throws {
        let response: FavoriteActionResponse = try await api.request(
            "/favorites/\(dessertId)",
            method: "DELETE",
            authorized: true
        )

        print("REMOVE FAVORITE RESPONSE:", response)
        notifyFavoritesChanged()
    }

    private func notifyFavoritesChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .favoritesDidChange, object: nil)
        }
    }
}


private struct FavoriteActionResponse: Decodable {
    let success: Bool
    let message: String?
    let error: String?
}

