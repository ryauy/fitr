import SwiftUI
import Kingfisher

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
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    filterBar
                    
                    if isLoading {
                        loadingView
                    } else if clothingItems.isEmpty {
                        emptyStateView
                    } else {
                        clothingGrid
                    }
                }
            }
            .navigationTitle("My Wardrobe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAddClothingSheet = true }) {
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
            .onReceive(NotificationCenter.default.publisher(for: .wardrobeUpdated)) { _ in
                loadClothingItems()
            }
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
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
            .padding(.vertical, 8)
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Your wardrobe is empty")
                .font(.headline)
            
            Button(action: { showAddClothingSheet = true }) {
                Text("Add Clothing")
                    .padding(.horizontal, 24)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var clothingGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(filteredItems) { item in
                    ClothingItemCard(item: item) {
                        markAsDirty(item)
                    }
                }
            }
            .padding()
        }
    }
    
    private var filteredItems: [ClothingItem] {
        let baseItems = clothingItems.filter { !$0.dirty }
        guard let filter = selectedFilter else { return baseItems }
        return baseItems.filter { $0.type == filter }
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
                isLoading = false
                switch result {
                case .success(let items):
                    // Filter out any items that might still be marked as dirty
                    clothingItems = items.filter { !$0.dirty }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func markAsDirty(_ item: ClothingItem) {
        FirebaseService.shared.markItemAsDirty(item: item) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    if let index = clothingItems.firstIndex(where: { $0.id == item.id }) {
                        clothingItems[index].dirty = true
                    }
                    NotificationCenter.default.post(name: .wardrobeUpdated, object: nil)
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct ClothingItemCard: View {
    let item: ClothingItem
    let onMarkDirty: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            KFImage(URL(string: item.imageURL))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .cornerRadius(10)
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text(item.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
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
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(15)
        }
    }
}

extension Notification.Name {
    static let wardrobeUpdated = Notification.Name("WardrobeUpdated")
}
