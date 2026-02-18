import SwiftUI
import SDWebImageSwiftUI

struct CategoryProductsView: View {
    let categoryId: String
    let categoryName: String
    
    @StateObject private var viewModel: CategoryProductsViewModel
    @EnvironmentObject var router: AppRouter
    @State private var wishlistError: String?
    @State private var isSearchPresented = false
    init(categoryId: String, categoryName: String) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        _viewModel = StateObject(wrappedValue: CategoryProductsViewModel(categoryId: categoryId))
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        // Item Count and Filter Button
                        HStack {
                            Text("\(viewModel.itemCount) items")
                                .font(.system(size: 14))
                                .foregroundColor(.black)
                            
                            Spacer()
                            
                            FilterSortButton(
                                isActive: viewModel.selectedMaterialFilter != "All" || viewModel.selectedSortOption != .defaultSort
                            ) {
                                viewModel.showFilterSheet = true
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // Products Grid
                        if !viewModel.filteredProducts.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(viewModel.filteredProducts) { product in
                                    ProductCard(product: product, router: router, onWishlistError: { wishlistError = $0 })
                                        .onAppear {
                                            // Load more when approaching the end
                                            if viewModel.shouldLoadMore(currentProduct: product) {
                                                viewModel.loadNextPage()
                                            }
                                        }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                            
                            // Loading indicator at bottom
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            }
                        } else if !viewModel.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "bag")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#CCCCCC"))
                                
                                Text("No products found")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#666666"))
                                
                                if categoryId == "test" {
                                    Text("(Using test categoryId - check console logs)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#999999"))
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .padding(.top, 60)
                        }
                    }
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingView()
            }
            
            // Error View
            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.refreshData()
                }
            }
        }
        .navigationTitle(categoryName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    router.pop()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) {
                            isSearchPresented = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white)
                    }
                    Button { router.navigate(to: .wishlist) } label: {
                        Image(systemName: "heart")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .animatedSearchBar(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.setSearchQuery($0) }
            ),
            isPresented: $isSearchPresented,
            placeholder: "Search products in this category"
        )
        .onAppear {
            router.currentRoute = .categoryProducts(categoryId: categoryId, categoryName: categoryName)
            if viewModel.products.isEmpty {
                viewModel.loadData()
            }
        }
        .refreshable {
            viewModel.refreshData()
        }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSortSheet(
                materials: viewModel.availableMaterials,
                selectedMaterial: Binding(
                    get: { viewModel.selectedMaterialFilter },
                    set: { viewModel.setMaterialFilter($0) }
                ),
                selectedSort: Binding(
                    get: { viewModel.selectedSortOption },
                    set: { viewModel.setSortOption($0) }
                )
            )
        }
        .alert("Wishlist", isPresented: Binding(
            get: { wishlistError != nil },
            set: { if !$0 { wishlistError = nil } }
        )) {
            Button("OK", role: .cancel) { wishlistError = nil }
        } message: {
            if let msg = wishlistError {
                Text(msg)
            }
        }
    }
}

// MARK: - Product Card
struct ProductCard: View {
    let product: Product
    let router: AppRouter
    var onWishlistError: ((String) -> Void)? = nil
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Product Image
            ZStack(alignment: .topTrailing) {
                if let firstImageUrl = product.imageUrls.first, !firstImageUrl.isEmpty, let url = URL(string: firstImageUrl) {
                    WebImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 170)
                            .clipped()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    }
                    .indicator(.activity)
                    .transition(.fade(duration: 0.3))
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 170)
                        .overlay(Image(systemName: "photo"))
                }
                
                // Favorite Button
                Button(action: {
                    let previousState = isFavorite
                    isFavorite.toggle()
                    Task {
                        do {
                            let result = try await WishlistService.shared.toggleWishlist(productId: product.id)
                            await MainActor.run { isFavorite = result }
                        } catch {
                            await MainActor.run {
                                isFavorite = previousState
                                onWishlistError?((error as? WishlistError)?.errorDescription ?? "Could not update wishlist")
                            }
                        }
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(12)
            }
            
            // Product Name
            Text(product.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.black)
                .lineLimit(2)
                .padding(.top, 12)
                .padding(.horizontal, 4)
            
            // Product Price
            Text(product.formattedPrice)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.top, 4)
                .padding(.horizontal, 4)
                .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            router.push(to: .itemDetail(productId: product.id))
        }
        .task {
            isFavorite = await WishlistService.shared.isInWishlistAsync(productId: product.id)
        }
    }
}

// MARK: - Filter & Sort Button
struct FilterSortButton: View {
    let isActive: Bool
    let action: () -> Void
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 14))
                
                Text("Filter & Sort")
                    .font(.system(size: 14))
                
                if isActive {
                    Circle()
                        .fill(primaryBrown)
                        .frame(width: 7, height: 7)
                }
            }
            .foregroundColor(isActive ? primaryBrown : Color(hex: "#666666"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? primaryBrown : Color(hex: "#E0E0E0"), lineWidth: 1)
            )
        }
    }
}

// MARK: - Sort Option Enum
enum SortOption: String, CaseIterable, Identifiable {
    case defaultSort = "Default"
    case priceLowToHigh = "Price: Low to High"
    case priceHighToLow = "Price: High to Low"
    
    var id: String { rawValue }
}

// MARK: - Filter & Sort Sheet
struct FilterSortSheet: View {
    @Environment(\.dismiss) var dismiss
    
    let materials: [String]
    @Binding var selectedMaterial: String
    @Binding var selectedSort: SortOption
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Filter & Sort")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 24)
            
            // Material Section
            VStack(alignment: .leading, spacing: 14) {
                Text("Material")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["All"] + materials, id: \.self) { material in
                            Button(action: {
                                selectedMaterial = material
                            }) {
                                Text(material)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedMaterial == material ? .white : Color(hex: "#666666"))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(selectedMaterial == material ? primaryBrown : Color(hex: "#E8E8E8"))
                                    .cornerRadius(20)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            
            // Sort by Price Section
            VStack(alignment: .leading, spacing: 0) {
                Text("Sort by Price")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.bottom, 8)
                
                ForEach(SortOption.allCases) { option in
                    Button(action: {
                        selectedSort = option
                    }) {
                        HStack(spacing: 14) {
                            // Radio button
                            ZStack {
                                Circle()
                                    .stroke(selectedSort == option ? primaryBrown : Color(hex: "#CCCCCC"), lineWidth: 2)
                                    .frame(width: 22, height: 22)
                                
                                if selectedSort == option {
                                    Circle()
                                        .fill(primaryBrown)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            
                            Text(option.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                            
                            Spacer()
                        }
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.white)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }
}

#Preview {
    CategoryProductsView(categoryId: "test", categoryName: "Ring")
        .environmentObject(AppRouter())
}
