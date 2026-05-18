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

let cafePickupAddress = "Проспект Мира, 95с1"

func orderStatusTitle(_ status: String, deliveryMode: String? = nil) -> String {
    let isPickup = deliveryMode == "pickup"

    switch normalizedOrderStatus(status) {
    case "new":
        return "Новый"
    case "processing":
        return "Готовится"
    case "shipped":
        return isPickup ? "Готов к выдаче" : "В пути"
    case "delivered":
        return isPickup ? "Выдан" : "Доставлен"
    case "cancelled":
        return "Отменён"
    default:
        return status
    }
}

func formattedOrderNumber(_ order: OrderDTO) -> String {
    if let formatted = order.formattedOrderNumber, !formatted.isEmpty {
        return formatted
    }

    return formattedOrderNumber(from: order.orderNumber ?? order.id)
}

private func formattedOrderNumber(from value: String) -> String {
    let digits = value.filter { $0.isNumber }
    let tenDigits: String

    if digits.count >= 10 {
        tenDigits = String(digits.suffix(10))
    } else if let number = UInt64(digits), !digits.isEmpty {
        tenDigits = String(format: "%010llu", number)
    } else {
        tenDigits = "0000000000"
    }

    let splitIndex = tenDigits.index(tenDigits.startIndex, offsetBy: 5)
    return "\(tenDigits[..<splitIndex])-\(tenDigits[splitIndex...])"
}

struct OrderDTO: Codable {
    let id: String
    let orderNumber: String?
    let formattedOrderNumber: String?
    let status: String
    let itemsCount: Int
    let subtotalPrice: Int?
    let deliveryFee: Int?
    let bonusPointsSpent: Int
    let bonusPointsEarned: Int
    let totalPrice: Int
    let comment: String?
    let deliveryMode: String?
    let paymentMode: String?
    let leaveAtDoor: Bool?
    let customerPhone: String?
    let createdAt: String?

    let address: AddressDTO?
    let items: [OrderItemDTO]?

    var isPickup: Bool {
        deliveryMode == "pickup"
    }

    var statusTitle: String {
        orderStatusTitle(status, deliveryMode: deliveryMode)
    }

    enum CodingKeys: String, CodingKey {
        case id, status, comment, address, items
        case orderNumber = "order_number"
        case formattedOrderNumber = "formatted_order_number"
        case itemsCount = "items_count"
        case subtotalPrice = "subtotal_price"
        case deliveryFee = "delivery_fee"
        case bonusPointsSpent = "bonus_points_spent"
        case bonusPointsEarned = "bonus_points_earned"
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
        orderNumber = try container.decodeIfPresent(String.self, forKey: .orderNumber)
        formattedOrderNumber = try container.decodeIfPresent(String.self, forKey: .formattedOrderNumber)
        status = normalizedOrderStatus(try container.decode(String.self, forKey: .status))
        itemsCount = try container.decode(Int.self, forKey: .itemsCount)
        subtotalPrice = try container.decodeIfPresent(Int.self, forKey: .subtotalPrice)
        deliveryFee = try container.decodeIfPresent(Int.self, forKey: .deliveryFee)
        bonusPointsSpent = (try container.decodeIfPresent(Int.self, forKey: .bonusPointsSpent)) ?? 0
        bonusPointsEarned = (try container.decodeIfPresent(Int.self, forKey: .bonusPointsEarned)) ?? 0
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
    let useBonusPoints: Bool
    let phone: String
    let customCake: CustomCakeOrderDTO?

    enum CodingKeys: String, CodingKey {
        case comment, phone
        case addressId = "address_id"
        case paymentMode = "payment_mode"
        case deliveryMode = "delivery_mode"
        case leaveAtDoor = "leave_at_door"
        case useBonusPoints = "use_bonus_points"
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

    // PATCH /orders/{id}/cancel
    func cancelOrder(id: String) async throws -> OrderDTO {
        try await api.request("/orders/\(id)/cancel", method: "PATCH", authorized: true)
    }

    // POST /orders
    func createOrder(dto: CreateOrderDTO) async throws -> OrderDTO {
        try await api.request("/orders", method: "POST", body: dto, authorized: true)
    }

}
