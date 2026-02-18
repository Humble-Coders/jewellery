import SwiftUI

struct CollectionProductsView: View {
    let productIds: [String]
    let collectionTitle: String
    
    @StateObject private var viewModel: CollectionProductsViewModel
    @EnvironmentObject var router: AppRouter
    @State private var wishlistError: String?
    
    init(productIds: [String], collectionTitle: String) {
        self.productIds = productIds
        self.collectionTitle = collectionTitle
        _viewModel = StateObject(wrappedValue: CollectionProductsViewModel(productIds: productIds, collectionTitle: collectionTitle))
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
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        } else if !viewModel.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "bag")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#CCCCCC"))
                                
                                Text("No products found")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#666666"))
                            }
                            .frame(maxWidth: .infinity, maxHeight: 100)
                            .padding(.top, 60)
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                LoadingView()
            }
            
            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                ErrorView(message: errorMessage) {
                    viewModel.refreshData()
                }
            }
        }
        .navigationTitle(collectionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
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
                Button { router.navigate(to: .wishlist) } label: {
                    Image(systemName: "heart")
                        .foregroundColor(.white)
                }
            }
        }
        .searchable(text: Binding(
            get: { viewModel.searchQuery },
            set: { viewModel.setSearchQuery($0) }
        ), prompt: "Search products in this collection")
        .onAppear {
            router.currentRoute = .carouselProducts(productIds: productIds, title: collectionTitle)
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

#Preview {
    NavigationStack {
        CollectionProductsView(productIds: [], collectionTitle: "Featured Collection")
            .environmentObject(AppRouter())
    }
}
