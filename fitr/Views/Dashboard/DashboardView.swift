//
//  Dash.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import CoreLocation

struct DashboardView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var locationManager = LocationManager()
    
    @State private var weather: Weather?
    @State private var outfit: Outfit?
    @State private var clothingItems: [ClothingItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.davyGrey))
                            .padding(.top, 100)
                    } else {
                        VStack(alignment: .leading, spacing: 20) {
                            // Welcome section
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Hello, \(authManager.currentUser?.name ?? "there")!")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppColors.davyGrey)
                                
                                Text("Here's your outfit for today")
                                    .font(.subheadline)
                                    .foregroundColor(AppColors.davyGrey.opacity(0.8))
                            }
                            .padding(.horizontal)
                            
                            // Weather section
                            if let weather = weather {
                                WeatherView(weather: weather)
                                    .padding(.horizontal)
                            } else {
                                Text("Weather data unavailable")
                                    .font(.headline)
                                    .foregroundColor(AppColors.davyGrey.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                            
                            // Outfit recommendation
                            if let outfit = outfit {
                                OutfitRecommendationView(outfit: outfit)
                                    .padding(.horizontal)
                            } else {
                                Text("Outfit recommendation unavailable")
                                    .font(.headline)
                                    .foregroundColor(AppColors.davyGrey.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            }
                            
                            // Quick actions
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Quick Actions")
                                    .font(.headline)
                                    .foregroundColor(AppColors.davyGrey)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 15) {
                                    QuickActionButton(
                                        icon: "camera.fill",
                                        title: "Add Clothing",
                                        color: AppColors.springRain
                                    ) {
                                        selectedTab = 1
                                    }
                                    
                                    QuickActionButton(
                                        icon: "arrow.clockwise",
                                        title: "Refresh",
                                        color: AppColors.lightPink
                                    ) {
                                        refreshData()
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding()
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(AppColors.peachSnaps.opacity(0.1).ignoresSafeArea())
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Wardrobe Tab
            WardrobeView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt.fill")
                }
                .tag(1)
            
            // Profile Tab
            ProfileView()
                .environmentObject(authManager)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(AppColors.davyGrey)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        isLoading = true
        errorMessage = nil
        
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        // Load clothing items
        FirebaseService.shared.getClothingItems(for: userId) { result in
            switch result {
            case .success(let items):    self.clothingItems = items
                
                // Once we have clothing items, get weather data
                self.loadWeatherData()
            case .failure(let error):
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load clothing items: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func loadWeatherData() {
        guard let location = locationManager.location else {
            // If location is not available yet, wait for it
            locationManager.requestLocation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.loadWeatherData()
            }
            return
        }
        
        WeatherService.shared.getWeather(for: location) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weather):
                    self.weather = weather
                    self.getOutfitRecommendation(weather: weather)
                case .failure(let error):
                    self.errorMessage = "Failed to load weather: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getOutfitRecommendation(weather: Weather) {
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        OutfitService.shared.getOutfitRecommendation(userId: userId, weather: weather, clothingItems: clothingItems) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let outfit):
                    self.outfit = outfit
                case .failure(let error):
                    self.errorMessage = "Failed to get outfit recommendation: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func refreshData() {
        loadData()
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(color)
            .cornerRadius(12)
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.location = location
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}
