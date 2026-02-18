import SwiftUI

struct AllJewelleryView: View {
    @StateObject private var viewModel: AllJewelleryViewModel
    @EnvironmentObject var router: AppRouter
    @State private var wishlistError: String?
    @State private var isSearchPresented = false
    
    private let primaryBrown = Color(red: 146/255, green: 111/255, blue: 111/255)
    
    init(initialMetalId: String? = nil, initialMetalName: String? = nil) {
        _viewModel = StateObject(wrappedValue: AllJewelleryViewModel(initialMetalId: initialMetalId, initialMetalName: initialMetalName))
    }
    
    private var filterHeader: some View {
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
            if let metal = viewModel.selectedMetalFilter {
                HStack {
                    Text("\(metal.name)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(primaryBrown)
                        .cornerRadius(20)
                    Button(action: { viewModel.clearMetalFilter() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(primaryBrown)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)
                .background(Color.white)
            }
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
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(Color.white)
        }
    }
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                filterHeader

                ScrollView {
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
                        }
                        .frame(maxWidth: .infinity, maxHeight: 100)
                        .padding(.top, 60)
                    }
                }
                .refreshable {
                    viewModel.refreshData()
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
        .blur(radius: router.showSidebar ? 3 : 0)
        .animation(.easeInOut(duration: 0.3), value: router.showSidebar)
        .navigationTitle(viewModel.selectedMetalFilter.map { "All Jewellery (\($0.name))" } ?? "All Jewellery")
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
            router.currentRoute = .allProducts(metalId: viewModel.selectedMetalFilter?.id, metalName: viewModel.selectedMetalFilter?.name)
            if viewModel.products.isEmpty {
                viewModel.loadData()
            }
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
        AllJewelleryView()
            .environmentObject(AppRouter())
    }
}
