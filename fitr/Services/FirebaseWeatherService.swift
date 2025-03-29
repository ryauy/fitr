//
//  FirebaseWeatherService.swift
//  fitr
//
//  Created by Akhil Gogineni on 3/29/25.
//

import Foundation
import FirebaseFunctions
import Combine

class FirebaseWeatherService {
    static let shared = FirebaseWeatherService()
    private lazy var functions = Functions.functions()
    
    @Published var currentWeather: WeatherData?
    @Published var errorMessage: String?
    
    func fetchWeather(for city: String? = nil,
                     coordinates: (lat: Double, lon: Double)? = nil) {
        Task {
            do {
                let result = try await callFunction(city: city, coordinates: coordinates)
                try await processResult(result)
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func callFunction(city: String?,
                            coordinates: (lat: Double, lon: Double)?) async throws -> HTTPSCallableResult {
        var parameters = [String: Any]()
        
        if let city = city {
            parameters["city"] = city
        } else if let coords = coordinates {
            parameters["lat"] = coords.lat
            parameters["lon"] = coords.lon
        }
        
        return try await functions.httpsCallable("getWeather").call(parameters)
    }
    
    private func processResult(_ result: HTTPSCallableResult) async throws {
        guard let data = result.data as? [String: Any],
              let jsonData = try? JSONSerialization.data(withJSONObject: data) else {
            throw URLError(.badServerResponse)
        }
        
        let weather = try JSONDecoder().decode(WeatherData.self, from: jsonData)
        
        await MainActor.run {
            currentWeather = weather
            errorMessage = nil
        }
    }
}
