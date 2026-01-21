import Foundation

final class CartService {
    static let shared = CartService()
    private init() {}

    private let api = APIClient.shared

    // GET /api/cart
    func getCart() async throws -> CartResponseDTO {
        // если у тебя возвращается {"data": {...}} -> поменяешь на DataWrapper<CartDTO>
        return try await api.request(
            path: "/cart",
            method: "GET",
            body: nil,
            authorized: true
        )
    }

    // POST /api/cart/items
    func addItem(dessertId: Int, qty: Int = 1) async throws -> CartResponseDTO {
        _ = try await api.request(
            path: "/cart/items",
            method: "POST",
            body: CartAddItemDTO(dessert_id: dessertId, qty: qty),
            authorized: true
        ) as SuccessDTO

        return try await getCart()
    }

    // PATCH /api/cart/items/{dessert}
    func setQty(dessertId: Int, qty: Int) async throws -> CartResponseDTO {
        _ = try await api.request(
            path: "/cart/items/\(dessertId)",
            method: "PATCH",
            body: CartSetQtyDTO(qty: qty),
            authorized: true
        ) as SuccessDTO

        return try await getCart()
    }

    // DELETE /api/cart/items/{dessert}
    func removeItem(dessertId: Int) async throws -> CartResponseDTO {
        return try await api.request(
            path: "/cart/items/\(dessertId)",
            method: "DELETE",
            body: nil,
            authorized: true
        )
    }

    // DELETE /api/cart
    func clearCart() async throws -> CartResponseDTO {
        return try await api.request(
            path: "/cart",
            method: "DELETE",
            body: nil,
            authorized: true
        )
    }
}
