//
//  FirebaseManager.swift
//  fitr
//
//  Created by Akhil Gogineni on 3/29/25.
//

import Foundation
import FirebaseFunctions

class FirebaseManager {
    static let shared = FirebaseManager()
    private let functions = Functions.functions()
    
    func getFullWeather(city: String? = nil,
                       lat: Double? = nil,
                       lon: Double? = nil) async throws -> WeatherData {
        var params: [String: Any] = [:]
        
        // Parameter validation
        if let city = city {
            params["city"] = city
        } else if let lat = lat, let lon = lon {
            params["lat"] = lat
            params["lon"] = lon
        } else {
            throw WeatherError.invalidParameters
        }
        
        do {
            let result = try await functions.httpsCallable("getFullWeather").call(params)
            
            guard let data = result.data as? [String: Any] else {
                throw WeatherError.invalidResponse
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            return try JSONDecoder().decode(WeatherData.self, from: jsonData)
            
        } catch let error as NSError {
            throw WeatherError.firebaseError(error.localizedDescription)
        }
    }
    
    enum WeatherError: Error {
        case invalidParameters
        case invalidResponse
        case firebaseError(String)
    }
}
