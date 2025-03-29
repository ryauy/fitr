//
//  WeatherService.swift
//  fitr
//
//  Created by Akhil Gogineni on 3/29/25.
//

import Foundation
import FirebaseFunctions
import CoreLocation

class WeatherService {
    public static let shared = WeatherService()
    private let functions = Functions.functions()
    
    func getWeather(for location: CLLocation, completion: @escaping (Result<WeatherData, Error>) -> Void) {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        functions.httpsCallable("getWeatherData").call([
            "lat": latitude,
            "lon": longitude
        ]) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = result?.data as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: data),
                  let weather = try? JSONDecoder().decode(WeatherData.self, from: jsonData) else {
                completion(.failure(NSError(domain: "WeatherService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode weather data"])))
                return
            }
            
            completion(.success(weather))
        }
    }
}
