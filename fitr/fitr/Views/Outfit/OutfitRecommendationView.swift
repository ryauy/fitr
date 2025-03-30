//
//  OutfitRecommendationView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import Kingfisher

struct OutfitRecommendationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var outfit: Outfit?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSuccessToast = true
    @State private var markedItems = Set<String>()
    @State private var animatingItemId: String? = nil
    
    // Weather and vibe parameters
    let weather: Weather
    let vibe: String
    
    var body: some View {
        VStack {
            if isLoading {
                loadingView
            } else if let error = errorMessage {
                errorView(message: error)
            } else if let outfit = outfit {
                outfitView(outfit: outfit)
            }
        }
        .onAppear{
            if outfit == nil {
                   loadOutfitRecommendation()
               }
        }
        .toast(isPresented: $showToast, message: toastMessage, isSuccess: isSuccessToast)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Creating your \(vibe) outfit...")
                .font(.headline)
                .foregroundColor(AppColors.davyGrey)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("Unable to create outfit")
                .font(.headline)
                .foregroundColor(AppColors.davyGrey)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppColors.davyGrey.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: loadOutfitRecommendation) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .padding()
                .background(AppColors.springRain)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
     q
    
    private func itemCard(item: ClothingItem) -> some View {
        VStack {
            HStack(alignment: .top, spacing: 12) {
                // Item image
                KFImage(URL(string: item.imageURL))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(AppColors.davyGrey)
                    
                    Text(item.type.rawValue)
                        .font(.subheadline)
                        .foregroundColor(AppColors.davyGrey.opacity(0.8))
                    
                    Text(item.color)
                        .font(.caption)
                        .foregroundColor(AppColors.davyGrey.opacity(0.6))
                    
                    HStack {
                        ForEach(item.weatherTags.prefix(2), id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.moonMist.opacity(0.3))
                                .cornerRadius(4)
                        }
                        ForEach(item.styleTags.prefix(1), id: \.self) { tag in
                            Text(tag.rawValue)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppColors.springRain.opacity(0.3))
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                // Mark as Dirty Button
                if !markedItems.contains(item.id) {
                    Button(action: { markAsDirty(item) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "basket")
                                .font(.system(size: 16))
                            Text("Dirty")
                                .font(.caption2)
                        }
                        .foregroundColor(.red)
                        .frame(width: 50)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                // Swap Button
                Button(action: {
                    swap(item)
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.2.circlepath")
                            .font(.system(size: 16))
                        Text("Swap")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .frame(width: 50)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
    
    private func loadOutfitRecommendation() {
        print("loading new outfit")
        isLoading = true
        errorMessage = nil
        
        guard let userId = authManager.currentUser?.id else {
            isLoading = false
            errorMessage = "User not authenticated"
            return
        }
        
        // Fetch clothing items from Firebase
        FirebaseService.shared.getCleanClothingItems(for: userId) { result in
            switch result {
            case .success(let clothingItems):
                // Generate outfit recommendation
                OutfitService.shared.getOutfitRecommendation(
                    userId: userId,
                    vibe: vibe,
                    weather: weather,
                    clothingItems: clothingItems
                ) { outfitResult in
                    DispatchQueue.main.async {
                        isLoading = false
                        
                        switch outfitResult {
                        case .success(let outfit):
                            self.outfit = outfit
                        case .failure(let error):
                            self.errorMessage = "Couldn't create outfit: \(error.localizedDescription)"
                        }
                    }
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    isLoading = false
                    errorMessage = "Failed to load wardrobe: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func markAsDirty(_ item: ClothingItem) {
        // Start animation
        animatingItemId = item.id
        
        // Call Firebase service
        FirebaseService.shared.markItemAsDirty(item: item) { result in
            DispatchQueue.main.async {
                // Stop animation
                animatingItemId = nil
                
                switch result {
                case .success:
                    // Add to marked items set
                    markedItems.insert(item.id)
                    
                    // Show success toast
                    toastMessage = "\(item.name) added to laundry basket"
                    isSuccessToast = true
                    showToast = true
                    
                    // Hide toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                    
                    // Update the outfit to remove the marked item
                    if var currentOutfit = self.outfit {
                        currentOutfit.items.removeAll(where: { $0.id == item.id })
                        self.outfit = currentOutfit
                    }
                    
                    // Post notification with a specific operation type
                    NotificationCenter.default.post(
                        name: Notification.Name("WardrobeUpdated"),
                        object: nil,
                        userInfo: ["operation": "markDirty", "itemId": item.id]
                    )
                    
                case .failure(let error):
                    // Show error toast
                    toastMessage = "Failed to update: \(error.localizedDescription)"
                    isSuccessToast = false
                    showToast = true
                    
                    // Hide toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showToast = false
                    }
                }
            }
        }
    }
    
    private func swap(_ item: ClothingItem) {
        // Start animation
        animatingItemId = item.id
        
        // Call Firebase service to swap the item
        FirebaseService.shared.swapItem(item: item) { result in
            DispatchQueue.main.async {
                // Stop animation
                animatingItemId = nil
                switch result {
                case .success(let newItem):
                    // Replace the old item with the new item in the outfit
                    if var currentOutfit = self.outfit {
                        if let index = currentOutfit.items.firstIndex(where: { $0.id == item.id }) {
                            currentOutfit.items[index] = newItem
                            self.outfit = currentOutfit
                        }
                    }
                    // Show success toast
                    toastMessage = "\(item.name) swapped successfully"
                    isSuccessToast = true
                    showToast = true
                    // Hide toast after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showToast = false
                    }
                case .failure(let error):
                    // Show error toast
                    toastMessage = "Failed to swap item: \(error.localizedDescription)"
                    isSuccessToast = false
                    showToast = true
                    // Hide toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showToast = false
                    }
                }
            }
        }
    }
    
    private func weatherIcon(for condition: WeatherCondition) -> String {
        switch condition {
        case .sunny:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        case .stormy:
            return "cloud.bolt.fill"
        case .windy:
            return "wind"
        case .foggy:
            return "cloud.fog.fill"
        }
    }
}
