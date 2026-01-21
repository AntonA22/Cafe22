//
//  CartDTO.swift
//  Cafe
//
//  Created by Антон Абалуев on 07.01.2026.
//

// MARK: - Cart DTO (1:1)

struct CartResponseDTO: Decodable {
    let data: CartDTO
}

struct CartDTO: Decodable {
    let id: Int
    let user_id: Int
    let items: [CartItemDTO]
    let total: Int
}

struct CartItemDTO: Decodable {
    let id: Int
    let dessert_id: Int
    let qty: Int
    let price: Int
    let sum: Int
    let dessert: CartDessertDTO
}

struct CartDessertDTO: Decodable {
    let id: Int
    let name: String
    let description: String
    let photos: [String]? // у тебя сейчас null, но в будущем может быть массив/urls
}


struct CartAddItemDTO: Encodable {
    let dessert_id: Int
    let qty: Int
}

struct CartSetQtyDTO: Encodable {
    let qty: Int
}

struct SuccessDTO: Decodable {
    let success: Bool?
    let message: String?
}
