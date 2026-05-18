//
//  UserDTO.swift
//  Cafe
//
//  Created by Антон Абалуев on 05.01.2026.
//

import Foundation

struct UserDTO: Decodable {
    let id: Int
    let username: String?
    let email: String?
    let phone: String?
    let firstName: String?
    let lastName: String?
    let isStaff: Bool
    let bonusPoints: Int
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, email, phone
        case firstName = "first_name"
        case lastName  = "last_name"
        case isStaff   = "is_staff"
        case bonusPoints = "bonus_points"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        username = try c.decodeIfPresent(String.self, forKey: .username)
        email = try c.decodeIfPresent(String.self, forKey: .email)
        phone = try c.decodeIfPresent(String.self, forKey: .phone)
        firstName = try c.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try c.decodeIfPresent(String.self, forKey: .lastName)
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)

        // ✅ не упадём, даже если ключ отсутствует
        isStaff = (try c.decodeIfPresent(Bool.self, forKey: .isStaff)) ?? false
        bonusPoints = (try c.decodeIfPresent(Int.self, forKey: .bonusPoints)) ?? 0
    }

    var fullName: String {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return name.isEmpty ? (username ?? "") : name
    }
}
