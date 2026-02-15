//
//  AddressService.swift
//  Cafe
//
//  Created by Антон Абалуев on 04.02.2026.
//

import Foundation

struct AddressDTO: Codable {
    let id: String
    let title: String
    let baseAddress: String
    let entrance: String?
    let intercom: String?
    let floor: String?
    let flat: String?
    let latitude: Double
    let longitude: Double
    let isDefault: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, entrance, intercom, floor, flat, latitude, longitude
        case baseAddress = "base_address"
        case isDefault  = "is_default"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        baseAddress = try c.decode(String.self, forKey: .baseAddress)
        entrance = try c.decodeIfPresent(String.self, forKey: .entrance)
        intercom = try c.decodeIfPresent(String.self, forKey: .intercom)
        floor = try c.decodeIfPresent(String.self, forKey: .floor)
        flat = try c.decodeIfPresent(String.self, forKey: .flat)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        isDefault = (try c.decodeIfPresent(Bool.self, forKey: .isDefault)) ?? false
    }
}

struct EmptyResponse: Decodable {}

struct AddressUpsertDTO: Codable {
    let title: String
    let baseAddress: String
    let entrance: String?
    let intercom: String?
    let floor: String?
    let flat: String?
    let latitude: Double
    let longitude: Double
}

final class AddressService {
    static let shared = AddressService()
    private init() {}

    private let api = APIClient.shared

    // GET /addresses
    func getAddresses() async throws -> [AddressDTO] {
        try await api.request("/addresses", method: "GET", authorized: true)
    }

    // POST /addresses
    func createAddress(_ dto: AddressUpsertDTO) async throws -> AddressDTO {
        try await api.request(
            "/addresses",
            method: "POST",
            body: dto,
            authorized: true
        )
    }

    // PATCH /addresses/{id}
    func updateAddress(id: String, dto: AddressUpsertDTO) async throws -> AddressDTO {
        try await api.request(
            "/addresses/\(id)",
            method: "PUT",
            body: dto,
            authorized: true
        )
    }

    // DELETE /addresses/{id}
    func deleteAddress(id: String) async throws {
        _ = try await api.request(
            "/addresses/\(id)",
            method: "DELETE",
            authorized: true
        ) as EmptyResponse
    }
    
    // POST /addresses/{id}/default
    func setDefaultAddress(id: String) async throws -> AddressDTO {
        try await api.request(
            "/addresses/\(id)/default",
            method: "POST",
            authorized: true
        )
    }
}
