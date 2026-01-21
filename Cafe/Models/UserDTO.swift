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

    var fullName: String {
        let name = [firstName, lastName].compactMap { $0 }.joined(separator: " ")
        return name.isEmpty ? (username ?? "") : name
    }

    enum CodingKeys: String, CodingKey {
        case id, username, email, phone
        case firstName = "first_name"
        case lastName = "last_name"
        case isStaff = "is_staff"
    }
}
