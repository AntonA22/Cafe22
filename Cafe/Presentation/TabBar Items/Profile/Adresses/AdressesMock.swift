//
//  AdressesMock.swift
//  Cafe
//
//  Created by Антон Абалуев on 03.02.2026.
//

import Foundation
import CoreLocation

//struct Address: Identifiable {
//    let id: UUID
//    var title: String          // "Дом", "Работа"
//    var subtitle: String       // "ул. ...", комментарий
//    var coordinate: Coordinate
//
//    init(id: UUID = UUID(), title: String, subtitle: String, coordinate: Coordinate) {
//        self.id = id
//        self.title = title
//        self.subtitle = subtitle
//        self.coordinate = coordinate
//    }
//}

import Foundation

struct Address: Identifiable {
    let id: UUID

    var title: String                 // Дом/Работа/...
    var baseAddress: String           // основной адрес (поиск/геокод), без деталей

    // детали
    var entrance: String?
    var intercom: String?
    var floor: String?
    var flat: String?

    var coordinate: Coordinate

    init(
        id: UUID = UUID(),
        title: String,
        baseAddress: String,
        entrance: String? = nil,
        intercom: String? = nil,
        floor: String? = nil,
        flat: String? = nil,
        coordinate: Coordinate
    ) {
        self.id = id
        self.title = title
        self.baseAddress = baseAddress
        self.entrance = entrance
        self.intercom = intercom
        self.floor = floor
        self.flat = flat
        self.coordinate = coordinate
    }

    /// Красиво отображаем в таблице
    var subtitle: String {
        var parts: [String] = []
        if !baseAddress.isEmpty { parts.append(baseAddress) }

        if let entrance, !entrance.isEmpty { parts.append("подъезд \(entrance)") }
        if let intercom, !intercom.isEmpty { parts.append("домофон \(intercom)") }
        if let floor, !floor.isEmpty { parts.append("этаж \(floor)") }
        if let flat, !flat.isEmpty { parts.append(flat) }

        return parts.joined(separator: ", ")
    }
}
