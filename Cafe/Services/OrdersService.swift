//
//  OrdersService.swift
//  Cafe
//
//  Created by Антон Абалуев on 06.02.2026.
//

import Foundation

// MARK: - DTO

struct OrderDTO: Codable {
    let id: String
    let status: String
    let itemsCount: Int
    let totalPrice: Int
    let comment: String?
    let createdAt: String?

    let address: AddressDTO?
    let items: [OrderItemDTO]?

    enum CodingKeys: String, CodingKey {
        case id, status, comment, address, items
        case itemsCount = "items_count"
        case totalPrice = "total_price"
        case createdAt  = "created_at"
    }
}

struct OrderItemDTO: Codable {
    let id: Int?
    let qty: Int
    let price: Int
    let sum: Int
    let dessert: Product?      // если у тебя Product совпадает с сервером
    let dessertId: Int?

    enum CodingKeys: String, CodingKey {
        case id, qty, price, sum, dessert
        case dessertId = "dessert_id"
    }
}

// запрос на создание заказа
struct CreateOrderDTO: Encodable {
    let addressId: String
    let comment: String?
    let paymentMode: String?     // "card" / "cash" — если хочешь сохранять
    let deliveryMode: String?    // "delivery" / "pickup"
    let leaveAtDoor: Bool?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case comment, phone
        case addressId = "address_id"
        case paymentMode = "payment_mode"
        case deliveryMode = "delivery_mode"
        case leaveAtDoor = "leave_at_door"
    }
}

struct OrdersResponse: Codable {
    let success: Bool
    let data: [OrderDTO]
}

final class OrdersService {
    static let shared = OrdersService()
    private init() {}

    private let api = APIClient.shared

    // GET /orders
    func getOrders() async throws -> [OrderDTO] {
        let response: OrdersResponse =
            try await api.request("/orders", method: "GET", authorized: true)

        return response.data   // <-- ВАЖНО! Берём массив из поля data
    }

    // GET /orders/{id}
    func getOrder(id: String) async throws -> OrderDTO {
        try await api.request("/orders/\(id)", method: "GET", authorized: true)
    }

    // POST /orders
    func createOrder(dto: CreateOrderDTO) async throws -> OrderDTO {
        try await api.request("/orders", method: "POST", body: dto, authorized: true)
    }

    // POST /orders/{id}/cancel
    func cancelOrder(id: String) async throws -> OrderDTO {
        try await api.request("/orders/\(id)/cancel", method: "POST", authorized: true)
    }
}
