//
//  OrdersService.swift
//  Cafe
//
//  Created by Антон Абалуев on 06.02.2026.
//

import Foundation

// MARK: - DTO

private func normalizedOrderStatus(_ status: String) -> String {
    status == "canceled" ? "cancelled" : status
}

func orderStatusTitle(_ status: String) -> String {
    switch normalizedOrderStatus(status) {
    case "new":
        return "Новый"
    case "processing":
        return "Готовится"
    case "shipped":
        return "В пути"
    case "delivered":
        return "Доставлен"
    case "cancelled":
        return "Отменён"
    default:
        return status
    }
}

struct OrderDTO: Codable {
    let id: String
    let status: String
    let itemsCount: Int
    let subtotalPrice: Int?
    let deliveryFee: Int?
    let totalPrice: Int
    let comment: String?
    let deliveryMode: String?
    let paymentMode: String?
    let leaveAtDoor: Bool?
    let customerPhone: String?
    let createdAt: String?

    let address: AddressDTO?
    let items: [OrderItemDTO]?

    var statusTitle: String {
        orderStatusTitle(status)
    }

    enum CodingKeys: String, CodingKey {
        case id, status, comment, address, items
        case itemsCount = "items_count"
        case subtotalPrice = "subtotal_price"
        case deliveryFee = "delivery_fee"
        case totalPrice = "total_price"
        case deliveryMode = "delivery_mode"
        case paymentMode = "payment_mode"
        case leaveAtDoor = "leave_at_door"
        case customerPhone = "customer_phone"
        case createdAt  = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        status = normalizedOrderStatus(try container.decode(String.self, forKey: .status))
        itemsCount = try container.decode(Int.self, forKey: .itemsCount)
        subtotalPrice = try container.decodeIfPresent(Int.self, forKey: .subtotalPrice)
        deliveryFee = try container.decodeIfPresent(Int.self, forKey: .deliveryFee)
        totalPrice = try container.decode(Int.self, forKey: .totalPrice)
        comment = try container.decodeIfPresent(String.self, forKey: .comment)
        deliveryMode = try container.decodeIfPresent(String.self, forKey: .deliveryMode)
        paymentMode = try container.decodeIfPresent(String.self, forKey: .paymentMode)
        leaveAtDoor = try container.decodeIfPresent(Bool.self, forKey: .leaveAtDoor)
        customerPhone = try container.decodeIfPresent(String.self, forKey: .customerPhone)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        address = try container.decodeIfPresent(AddressDTO.self, forKey: .address)
        items = try container.decodeIfPresent([OrderItemDTO].self, forKey: .items)
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
    let addressId: String?
    let comment: String?
    let paymentMode: String
    let deliveryMode: String
    let leaveAtDoor: Bool?
    let phone: String
    let customCake: CustomCakeOrderDTO?

    enum CodingKeys: String, CodingKey {
        case comment, phone
        case addressId = "address_id"
        case paymentMode = "payment_mode"
        case deliveryMode = "delivery_mode"
        case leaveAtDoor = "leave_at_door"
        case customCake = "custom_cake"
    }
}

struct CustomCakeOrderDTO: Encodable {
    let designId: String
    let designName: String
    let weightTitle: String
    let weightGrams: Int
    let inscription: String?
    let wishes: String?
    let filling: String?
    let accent: String?
    let composition: String?
    let previewImageBase64: String?
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
