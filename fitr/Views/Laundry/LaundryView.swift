import SwiftUI
import Kingfisher

struct LaundryView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var laundryItems: [ClothingItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedItems: Set<String> = []
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var isSuccessToast = true
    @State private var isEditing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if !laundryItems.isEmpty {
                        washControls
                    }
                    
                    if isLoading {
                        loadingView
                    } else if laundryItems.isEmpty {
                        emptyStateView
                    } else {
                        laundryItemsList
                    }
                    
                    errorView
                }
            }
            .navigationTitle("Laundry Basket")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .onAppear {
                loadLaundryItems()
            }
            .toast(isPresented: $showToast, message: toastMessage, isSuccess: isSuccessToast)
        }
    }
    
    private var washControls: some View {
        HStack {
            if isEditing {
                Button(action: toggleSelectAll) {
                    Text(selectedItems.count == laundryItems.count ? "Deselect All" : "Select All")
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button(action: washSelectedItems) {
                    HStack {
                        Image(systemName: "washer.fill")
                        Text("Wash (\(selectedItems.count))")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(selectedItems.isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                    .foregroundColor(selectedItems.isEmpty ? Color.gray : .white)
                    .cornerRadius(8)
                }
                .disabled(selectedItems.isEmpty)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(.easeInOut, value: isEditing)
    }
    
    private var editButton: some View {
        Button(action: {
            isEditing.toggle()
            if !isEditing {
                selectedItems.removeAll()
            }
        }) {
            Text(isEditing ? "Done" : "Edit")
        }
    }
    
    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "basket.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.4))
            
            Text("Your laundry basket is empty")
                .font(.headline)
            
            Text("Mark items as dirty to add them here")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var laundryItemsList: some View {
        List {
            ForEach(laundryItems) { item in
                HStack {
                    if isEditing {
                        Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedItems.contains(item.id) ? .blue : .gray)
                            .onTapGesture {
                                toggleItemSelection(item.id)
                            }
                    }
                    
                    KFImage(URL(string: item.imageURL))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(item.type.rawValue)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.leading, 8)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if isEditing {
                        toggleItemSelection(item.id)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var errorView: some View {
        Group {
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
    }
    
    private func loadLaundryItems() {
        guard let userId = authManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            isLoading = false
            return
        }
        
        isLoading = true
        FirebaseService.shared.getLaundryItems(for: userId) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let items):
                    laundryItems = items
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func toggleItemSelection(_ itemId: String) {
        if selectedItems.contains(itemId) {
            selectedItems.remove(itemId)
        } else {
            selectedItems.insert(itemId)
        }
    }
    
    private func toggleSelectAll() {
        if selectedItems.count == laundryItems.count {
            selectedItems.removeAll()
        } else {
            selectedItems = Set(laundryItems.map { $0.id })
        }
    }
    
    private func washSelectedItems() {
        guard let userId = authManager.currentUser?.id else { return }
        
        let itemsToWash = laundryItems.filter { selectedItems.contains($0.id) }
        FirebaseService.shared.washItems(items: itemsToWash) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // Update local state
                    self.laundryItems.removeAll { selectedItems.contains($0.id) }
                    self.selectedItems.removeAll()
                    
                    // Show success toast
                    self.showToast(message: "Items washed and returned to wardrobe", isSuccess: true)
                    
                    // Refresh wardrobe
                    NotificationCenter.default.post(name: .wardrobeUpdated, object: nil)
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showToast(message: "Failed to wash items", isSuccess: false)
                }
            }
        }
    }
    
    private func showToast(message: String, isSuccess: Bool) {
        toastMessage = message
        isSuccessToast = isSuccess
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showToast = false
        }
    }
}
