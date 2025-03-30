//
//  Outfit.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import Foundation

struct Outfit: Identifiable, Codable {
    var id: String
    var userId: String
    var items: [ClothingItem]
    var weather: Weather
    var createdAt: Date
    var description: String
    let vibe: String? // Add this property, make it optional for backward compatibility

    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case items
        case weather
        case createdAt = "created_at"
        case description
        case vibe
    }
}

enum StyleTag: String, Codable, CaseIterable {
    case casual
    case formal
    case business
    case elegant
    case athletic
    case sporty
    case comfortable
    case trendy
    case stylish
    case everyday
    case warm
}
