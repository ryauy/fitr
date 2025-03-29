//
//  Weather.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import Foundation

public struct WeatherData: Codable {
    let coord: Coordinates
    let weather: [Weather]
    let main: Main
    let name: String
    let wind: Wind
    let sys: Sys
    let dt: TimeInterval
    
    struct Coordinates: Codable {
        let lon: Double
        let lat: Double
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int
        let humidity: Int
        
        var temperatureF: Int { Int(temp) }
        var feelsLikeF: Int { Int(feels_like) }
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int
        
        var speedMPH: Int { Int(speed) }
    }
    
    struct Sys: Codable {
        let country: String?
        let sunrise: TimeInterval?
        let sunset: TimeInterval?
    }
}
