//
//  WardrobeView.swift
//  fitr
//
//  Created by Ryan Nguyen on 3/29/25.
//

import SwiftUI
import Firebase

struct WardrobeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var clothingItems: [ClothingItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showAddClothingSheet = false
    @State private var selectedFilter: ClothingType?
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.peachSnaps.opacity(0.2).ignoresSafeArea()
                
                VStack {
                    // Filter options
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                action: { selectedFilter = nil }
                            )
                            
                            ForEach(ClothingType.allCases, id: \.self) { type in
                                FilterButton(
                                    title: type.rawValue,
                                    isSelected: selectedFilter == type,
                                    action: { selectedFilter = type }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 5)
                    }
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppColors.davyGrey))
                        Spacer()
                    } else if clothingItems.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "tshirt")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.davyGrey.opacity(0.6))
                            
                            Text("Your wardrobe is empty")
                                .font(.headline)
                                .foregroundColor(AppColors.davyGrey)
                            
                            Text("Add some clothing items to get started")
                                .font(.subheadline)
                                .foregroundColor(AppColors.davyGrey.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                showAddClothingSheet = true
                            }) {
                                Text("Add Clothing")
                                    .padding(.horizontal, 30)
                            }
                            .primaryButtonStyle()
                        }
                        .padding()
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 16) {
                                ForEach(filteredClothingItems) { item in
                                    ClothingItemView(item: item)
                                        .contextMenu {
                                            Button(role: .destructive, action: {
                                                deleteClothingItem(item)
                                            }) {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .padding()
                        }
                    }
                    
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("My Wardrobe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddClothingSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddClothingSheet) {
                AddClothingView()
                    .environmentObject(authManager)
            }
            .onAppear {
                loadClothingItems()
            }
        }
    }
    
    var filteredClothingItems: [ClothingItem] {
        if let filter = selectedFilter {
            return clothingItems.filter { $0.type == filter }
        } else {
            return clothingItems
        }
    }
    
    private func loadClothingItems() {
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        
        FirebaseService.shared.getClothingItems(for: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let items):
                    self.clothingItems = items
                case .failure(let error):
                    self.errorMessage = "Failed to load clothing items: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func deleteClothingItem(_ item: ClothingItem) {
        guard let userId = authManager.currentUser?.id else { return }
        
        FirebaseService.shared.deleteClothingItem(itemId: item.id, userId: userId, imageURL: item.imageURL) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = self.clothingItems.firstIndex(where: { $0.id == item.id }) {
                        self.clothingItems.remove(at: index)
                    }
                case .failure(let error):
                    self.errorMessage = "Failed to delete item: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? AppColors.springRain : AppColors.moonMist.opacity(0.5))
                .foregroundColor(isSelected ? .white : AppColors.davyGrey)
                .cornerRadius(20)
        }
    }
}

struct WeatherTagButton: View {
    let tag: WeatherTag
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? AppColors.lightPink : AppColors.moonMist.opacity(0.5))
                .foregroundColor(isSelected ? .white : AppColors.davyGrey)
                .cornerRadius(20)
        }
    }
}
