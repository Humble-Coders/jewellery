import SwiftUI
import SDWebImageSwiftUI

struct WishlistView: View {
    @StateObject private var viewModel = WishlistViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var isSearchPresented = false
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    private let filterTextGray = Color(hex: "#666666")
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.filterOptions, id: \.self) { filter in
                            FilterPill(
                                title: filter,
                                isSelected: viewModel.selectedFilter == filter,
                                primaryColor: primaryBrown
                            ) {
                                viewModel.selectFilter(filter)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .scrollBounceBehavior(.basedOnSize)
                .background(Color.white)
                
                // Item Count and Filter Button
                HStack {
                    Text("\(viewModel.filteredProducts.count) items")
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
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Color.white)

                ScrollView {
                    if viewModel.filteredProducts.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(viewModel.filteredProducts) { product in
                                WishlistProductCard(
                                    product: product,
                                    primaryColor: primaryBrown,
                                    onTap: {
                                        router.push(to: .itemDetail(productId: product.id))
                                    },
                                    onRemove: {
                                        viewModel.removeFromWishlist(productId: product.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if viewModel.showError, let message = viewModel.errorMessage {
                ErrorView(message: message) {
                    viewModel.forceRefreshData()
                }
            }
        }
        .blur(radius: router.showSidebar ? 3 : 0)
        .animation(.easeInOut(duration: 0.3), value: router.showSidebar)
        .navigationTitle("Wishlist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) { router.showSidebar = true }
                } label: {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.white)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeOut(duration: 0.25)) {
                        isSearchPresented = true
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                }
            }
        }
        .animatedSearchBar(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.setSearchQuery($0) }
            ),
            isPresented: $isSearchPresented,
            placeholder: "Search products"
        )
        .onAppear {
            router.currentRoute = .wishlist
            router.selectedTab = .favorites
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
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(filterTextGray)
            
            Text("Your wishlist is empty")
                .font(.system(size: 16))
                .foregroundColor(filterTextGray)
            
            Text("Add items from our collection to see them here")
                .font(.system(size: 14))
                .foregroundColor(filterTextGray.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }
}

// MARK: - Filter Pill
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let primaryColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : Color(hex: "#666666"))
                .padding(.horizontal, 17)
                .padding(.vertical, 10)
                .background(isSelected ? primaryColor : Color(hex: "#E8E8E8"))
                .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Wishlist Product Card
struct WishlistProductCard: View {
    let product: Product
    let primaryColor: Color
    let onTap: () -> Void
    let onRemove: () -> Void
    
    private let filterTextGray = Color(hex: "#666666")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                VStack(alignment: .leading, spacing: 0) {
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
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18))
                            .foregroundColor(primaryColor)
                            .padding(8)
                    }
                    
                    Text(product.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(2)
                        .padding(.top, 12)
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(product.formattedPrice)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.top, 4)
                        .padding(.horizontal, 7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
            
            Button(action: onRemove) {
                Text("Remove")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(filterTextGray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: "#E0E0E0"), lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            .padding(.horizontal, 7)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        WishlistView()
            .environmentObject(AppRouter())
    }
}
