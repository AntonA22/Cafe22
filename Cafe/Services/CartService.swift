import Foundation

// MARK: - Service

final class CartService {
    static let shared = CartService()
    private init() {}

    private let api = APIClient.shared

    // GET /cart  -> {"data": {...}}
    func getCart() async throws -> CartDTO {
        try await api.request("/cart", method: "GET", authorized: true)
    }

    // POST /cart/items
    func addItem(dessertId: Int, qty: Int = 1) async throws -> CartDTO {
        let _: SuccessDTO = try await api.request(
            "/cart/items",
            method: "POST",
            body: CartAddItemDTO(dessertId: dessertId, qty: qty),
            authorized: true
        )
        return try await getCart()
    }

    // PATCH /cart/items/{dessertId}
    func setQty(dessertId: Int, qty: Int) async throws -> CartDTO {
        let _: SuccessDTO = try await api.request(
            "/cart/items/\(dessertId)",
            method: "PATCH",
            body: CartSetQtyDTO(qty: qty),
            authorized: true
        )
        return try await getCart()
    }

    // DELETE /cart/items/{dessertId} -> {"data": {...}}
    func removeItem(dessertId: Int) async throws -> CartDTO {
        try await api.request(
            "/cart/items/\(dessertId)",
            method: "DELETE",
            authorized: true
        )
    }

    // DELETE /cart -> {"data": {...}}
    func clearCart() async throws -> CartDTO {
        try await api.request(
            "/cart",
            method: "DELETE",
            authorized: true
        )
    }
}

