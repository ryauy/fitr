//
//  ClothingItem.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//


import Foundation

enum ClothingType: String, Codable, CaseIterable {
    case tShirt = "T-Shirt"
    case shirt = "Shirt"
    case sweater = "Sweater"
    case jacket = "Jacket"
    case coat = "Coat"
    case jeans = "Jeans"
    case pants = "Pants"
    case shorts = "Shorts"
    case skirt = "Skirt"
    case dress = "Dress"
    case shoes = "Shoes"
    case accessory = "Accessory"
    case other = "Other"
}

struct ClothingItem: Identifiable, Codable {
    var id: String
    var userId: String
    var imageURL: String
    var type: ClothingType
    var color: String
    var name: String
    var createdAt: Date
    var weatherTags: [WeatherTag]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case imageURL = "image_url"
        case type
        case color
        case name
        case createdAt = "created_at"
        case weatherTags = "weather_tags"
    }
}

enum WeatherTag: String, Codable, CaseIterable {
    case hot = "Hot"
    case warm = "Warm"
    case cool = "Cool"
    case cold = "Cold"
    case rainy = "Rainy"
    case snowy = "Snowy"
    case windy = "Windy"
}

struct ClothingItem: Identifiable, Codable, Equatable {
    // Your existing properties
    
    // Add this static function for Equatable conformance
    static func == (lhs: ClothingItem, rhs: ClothingItem) -> Bool {
        return lhs.id == rhs.id
    }
}
