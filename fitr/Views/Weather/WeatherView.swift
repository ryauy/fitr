//
//  WeatherView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//
import SwiftUI

struct WeatherView: View {
    let weather: WeatherData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                weatherIcon
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.davyGrey)
                
                VStack(alignment: .leading) {
                    Text("\(weather.main.temperatureF)°F")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.davyGrey)
                    
                    Text(weatherCondition)
                        .font(.headline)
                        .foregroundColor(AppColors.davyGrey.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(weather.name)
                        .font(.headline)
                        .foregroundColor(AppColors.davyGrey)
                    
                    Text(currentFormattedDate)
                        .font(.subheadline)
                        .foregroundColor(AppColors.davyGrey.opacity(0.8))
                }
            }
            
            HStack(spacing: 20) {
                WeatherDetailItem(
                    icon: "humidity",
                    value: "\(weather.main.humidity)%",
                    label: "Humidity"
                )
                
                WeatherDetailItem(
                    icon: "wind",
                    value: "\(weather.wind.speedMPH) mph",
                    label: "Wind"
                )
            }
            .padding(.top, 5)
        }
        .padding()
        .background(weatherBackgroundColor.opacity(0.2))
        .cornerRadius(15)
    }
    
    private var weatherCondition: String {
        weather.weather.first?.description.capitalized ?? "N/A"
    }
    
    private var weatherIcon: some View {
        let condition = weather.weather.first?.main.lowercased() ?? ""
        
        if condition.contains("rain") {
            return Image(systemName: "cloud.rain.fill")
        } else if condition.contains("snow") {
            return Image(systemName: "cloud.snow.fill")
        } else if condition.contains("thunder") {
            return Image(systemName: "cloud.bolt.fill")
        } else if condition.contains("cloud") {
            return Image(systemName: "cloud.fill")
        } else if weather.wind.speedMPH > 15 {
            return Image(systemName: "wind")
        } else if condition.contains("fog") || condition.contains("mist") {
            return Image(systemName: "cloud.fog.fill")
        } else {
            return Image(systemName: "sun.max.fill")
        }
    }
    
    private var weatherBackgroundColor: Color {
        let condition = weather.weather.first?.main.lowercased() ?? ""
        
        if condition.contains("rain") || condition.contains("fog") || condition.contains("mist") {
            return AppColors.davyGrey.opacity(0.5)
        } else if condition.contains("snow") {
            return AppColors.moonMist
        } else if condition.contains("thunder") {
            return AppColors.davyGrey
        } else if condition.contains("cloud") {
            return AppColors.moonMist
        } else if weather.wind.speedMPH > 15 {
            return AppColors.springRain
        } else {
            return AppColors.peachSnaps
        }
    }
    
    private var currentFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter.string(from: Date())
    }
}

struct WeatherDetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon == "humidity" ? "drop.fill" : "wind")
                .foregroundColor(AppColors.davyGrey.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.davyGrey)
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(AppColors.davyGrey.opacity(0.7))
            }
        }
    }
}
