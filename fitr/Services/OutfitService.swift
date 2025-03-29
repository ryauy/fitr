//
//  OutfitService.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import Foundation

class OutfitService {
    static let shared = OutfitService()
    
    func getOutfitRecommendation(userId: String, weather: Weather, clothingItems: [ClothingItem], completion: @escaping (Result<Outfit, Error>) -> Void) {
        // Always try to get recommendation from backend first
        getRecommendationFromBackend(userId: userId, weather: weather, clothingItems: clothingItems) { result in
            switch result {
            case .success(let outfit):
                completion(.success(outfit))
            case .failure(let error):
                // If backend fails, fallback to local recommendation
                print("Backend recommendation failed: \(error.localizedDescription). Falling back to local recommendation.")
                self.getLocalRecommendation(userId: userId, weather: weather, clothingItems: clothingItems, completion: completion)
            }
        }
    }
    
    private func getRecommendationFromBackend(userId: String, weather: Weather, clothingItems: [ClothingItem], completion: @escaping (Result<Outfit, Error>) -> Void) {
        guard let url = URL(string: "\(APIEndpoints.baseURL)\(APIEndpoints.outfitRecommendationEndpoint)") else {
            completion(.failure(NSError(domain: "OutfitService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        // Prepare request body
        let requestBody = OutfitRequestBody(userId: userId, weather: weather, clothingItems: clothingItems)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OutfitService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the response from the AI backend
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let outfit = try decoder.decode(Outfit.self, from: data)
                completion(.success(outfit))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func getLocalRecommendation(userId: String, weather: Weather, clothingItems: [ClothingItem], completion: @escaping (Result<Outfit, Error>) -> Void) {
        // Simple local recommendation logic based on weather
        guard !clothingItems.isEmpty else {
            completion(.failure(NSError(domain: "OutfitService", code: 2, userInfo: [NSLocalizedDescriptionKey: "No clothing items available"])))
            return
        }
        
        // Determine appropriate weather tags based on current weather
        var appropriateWeatherTags: [WeatherTag] = []
        
        // Temperature-based tags
        if weather.temperature > 25 {
            appropriateWeatherTags.append(.hot)
        } else if weather.temperature > 18 {
            appropriateWeatherTags.append(.warm)
        } else if weather.temperature > 10 {
            appropriateWeatherTags.append(.cool)
        } else {
            appropriateWeatherTags.append(.cold)
        }
        
        // Condition-based tags
        switch weather.condition {
        case .rainy:
            appropriateWeatherTags.append(.rainy)
        case .snowy:
            appropriateWeatherTags.append(.snowy)
        case .windy:
            appropriateWeatherTags.append(.windy)
        default:
            break
        }
        
        // Filter clothing items that match the appropriate weather tags
        let filteredItems = clothingItems.filter { item in
            return item.weatherTags.contains { appropriateWeatherTags.contains($0) }
        }
        
        // If no matching items, use all items
        let itemsToUse = filteredItems.isEmpty ? clothingItems : filteredItems
        
        // Select one item of each necessary type
        var selectedItems: [ClothingItem] = []
        
        // For cold weather, we need more layers
        if appropriateWeatherTags.contains(.cold) {
            // Try to find a top layer (coat or jacket)
            if let topLayer = itemsToUse.first(where: { $0.type == .coat || $0.type == .jacket }) {
                selectedItems.append(topLayer)
            }
            
            // Try to find a mid layer (sweater)
            if let midLayer = itemsToUse.first(where: { $0.type == .sweater }) {
                selectedItems.append(midLayer)
            }
        }
        
        // Always need a base layer (shirt or t-shirt)
        if let baseLayer = itemsToUse.first(where: { $0.type == .shirt || $0.type == .tShirt }) {
            selectedItems.append(baseLayer)
        }
        
        // Always need bottoms (pants, jeans, shorts, or skirt)
        if let bottoms = itemsToUse.first(where: { $0.type == .pants || $0.type == .jeans || $0.type == .shorts || $0.type == .skirt }) {
            selectedItems.append(bottoms)
        }
        
        // Always need shoes
        if let shoes = itemsToUse.first(where: { $0.type == .shoes }) {
            selectedItems.append(shoes)
        }
        
        // If we have a dress, it can replace top and bottoms
        if selectedItems.isEmpty || (!selectedItems.contains(where: { $0.type == .shirt || $0.type == .tShirt }) &&
                                    !selectedItems.contains(where: { $0.type == .pants || $0.type == .jeans || $0.type == .shorts || $0.type == .skirt })) {
            if let dress = itemsToUse.first(where: { $0.type == .dress }) {
                selectedItems.append(dress)
            }
        }
        
        // If we still don't have enough items, add some random ones
        if selectedItems.count < 2 {
            let remainingItems = itemsToUse.filter { !selectedItems.contains($0) }
            selectedItems.append(contentsOf: Array(remainingItems.prefix(2 - selectedItems.count)))
        }
        
        // Create description based on selected items
        let description = createOutfitDescription(items: selectedItems, weather: weather)
        
        // Create outfit
        let outfit = Outfit(
            id: UUID().uuidString,
            userId: userId,
            items: selectedItems,
            weather: weather,
            createdAt: Date(),
            description: description
        )
        
        completion(.success(outfit))
    }
    
    private func createOutfitDescription(items: [ClothingItem], weather: Weather) -> String {
        let itemDescriptions = items.map { "\($0.color) \($0.type.rawValue.lowercased())" }
        
        var description = "For today's weather (\(Int(weather.temperature))°C, \(weather.condition.rawValue)), "
        
        if itemDescriptions.isEmpty {
            description += "I couldn't find suitable items in your wardrobe."
        } else if itemDescriptions.count == 1 {
            description += "I recommend wearing your \(itemDescriptions[0])."
        } else {
            let lastItem = itemDescriptions.last!
            let otherItems = itemDescriptions.dropLast().joined(separator: ", ")
            description += "I recommend wearing your \(otherItems) and \(lastItem)."
        }
        
        return description
    }
}

struct OutfitRequestBody: Codable {
    let userId: String
    let weather: Weather
    let clothingItems: [ClothingItem]
}
