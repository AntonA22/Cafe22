// MARK: - DTO (под твой JSON)

struct CartDTO: Decodable {
    let id: Int
    let userId: Int
    let items: [CartItemDTO]
    let total: Int

    enum CodingKeys: String, CodingKey {
        case id, items, total
        case userId = "user_id"
    }
}

struct CartItemDTO: Decodable {
    let id: Int
    let itemType: String
    let dessertId: Int?
    let customCakeCartItemId: Int?
    let qty: Int
    let price: Int
    let sum: Int
    let dessert: CartDessertDTO
    let customCake: CustomCakeOrderDTO?

    enum CodingKeys: String, CodingKey {
        case id, qty, price, sum, dessert
        case customCake = "custom_cake"
        case itemType = "item_type"
        case dessertId = "dessert_id"
        case customCakeCartItemId = "custom_cake_cart_item_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType) ?? "dessert"
        dessertId = try container.decodeIfPresent(Int.self, forKey: .dessertId)
        customCakeCartItemId = try container.decodeIfPresent(Int.self, forKey: .customCakeCartItemId)
        qty = try container.decode(Int.self, forKey: .qty)
        price = try container.decode(Int.self, forKey: .price)
        sum = try container.decode(Int.self, forKey: .sum)
        dessert = try container.decode(CartDessertDTO.self, forKey: .dessert)
        customCake = try container.decodeIfPresent(CustomCakeOrderDTO.self, forKey: .customCake)
    }

    var isCustomCake: Bool {
        itemType == "custom_cake"
    }
}

struct CartDessertDTO: Decodable {
    let id: Int?
    let name: String
    let description: String
    let photos: [String]?

    enum CodingKeys: String, CodingKey {
        case id, name, description, photos
    }
}

// request bodies
struct CartAddItemDTO: Encodable {
    let dessertId: Int
    let qty: Int
}

struct CartAddCustomCakeDTO: Encodable {
    let qty: Int
    let customCake: CustomCakeOrderDTO
}

struct CartSetQtyDTO: Encodable {
    let qty: Int
}

// ответ на POST/PATCH часто {"success":true,"message":"..."} — ок
struct SuccessDTO: Decodable {
    let success: Bool?
    let message: String?
}
