//
//  Constants.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI

struct AppColors {
    static let lightPink = Color("EDAFB8")
    static let peachSnaps = Color("F7E1D7")
    static let moonMist = Color("DEDBD2")
    static let springRain = Color("B0C4B1")
    static let davyGrey = Color("4A5759")
}

struct APIKeys {
    static let openWeatherMapKey = "YOUR_OPENWEATHERMAP_API_KEY"
}

struct APIEndpoints {
    static let baseURL = "YOUR_BACKEND_BASE_URL"
    static let weatherEndpoint = "/weather"
    static let outfitRecommendationEndpoint = "/outfit-recommendation"
    static let clothingClassificationEndpoint = "/classify-clothing"
}

struct FirebaseCollections {
    static let users = "users"
    static let clothingItems = "clothingItems"
    static let outfits = "outfits"
}
