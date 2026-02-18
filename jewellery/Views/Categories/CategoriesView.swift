import SwiftUI
import SDWebImageSwiftUI

private let categoriesHeaderColor = Color(red: 186/255, green: 143/255, blue: 143/255)

struct CategoriesView: View {
    @StateObject private var viewModel = CategoriesViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var isSearchPresented = false
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: Theme.Spacing.xl) {
                        // Categories Grid Section
                        let displayCategories = viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ? viewModel.categories : viewModel.filteredCategories
                        let displayCollections = viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty ? viewModel.collections : viewModel.filteredCollections
                        if !displayCategories.isEmpty {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(displayCategories) { category in
                                    CategoryCard(category: category, router: router)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 16)
                            .padding(.bottom, 0)
                        }
                        
                        
                        // Featured Collections Section
                        if !displayCollections.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                                Text("Featured Collections")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                
                                VStack(spacing: 12) {
                                    ForEach(displayCollections) { collection in
                                        FeaturedCollectionCard(collection: collection, router: router)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.top, 8)
                            .padding(.bottom, Theme.Spacing.xl)
                        }
                        if !viewModel.searchQuery.trimmingCharacters(in: .whitespaces).isEmpty && displayCategories.isEmpty && displayCollections.isEmpty && !viewModel.isLoading {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(Color(hex: "#9A9A9A"))
                                Text("No categories or collections match \"\(viewModel.searchQuery)\"")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }
                            .frame(maxWidth: .infinity)
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
        .blur(radius: router.showSidebar ? 3 : 0)
        .animation(.easeInOut(duration: 0.3), value: router.showSidebar)
        .navigationTitle("Categories")
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
            ToolbarItem(placement: .principal) {
                Text("Categories")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
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
                set: { viewModel.searchQuery = $0 }
            ),
            isPresented: $isSearchPresented,
            placeholder: "Search categories and collections"
        )
        .onAppear {
            router.selectedTab = .categories
            if viewModel.categories.isEmpty {
                viewModel.refreshData()
            }
        }
        .refreshable {
            viewModel.refreshData(forceRefresh: true)
        }
    }
}

// MARK: - Category Card
struct CategoryCard: View {
    let category: Category
    let router: AppRouter
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Category Image
            if !category.imageUrl.isEmpty {
                WebImage(url: URL(string: category.imageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .frame(height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 130)
                    .overlay(Image(systemName: "photo"))
            }
            
            // Dark overlay gradient
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .bottom,
                endPoint: .center
            )
            .frame(height: 130)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Category Name
            Text(category.name)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .onTapGesture {
            print("🔗 Navigating to categoryProducts - categoryId: '\(category.id)', categoryName: '\(category.name)'")
            router.push(to: .categoryProducts(categoryId: category.id, categoryName: category.name))
        }
    }
}

// MARK: - Featured Collection Card
struct FeaturedCollectionCard: View {
    let collection: ThemedCollection
    let router: AppRouter
    
    private let cardHeight: CGFloat = 70
    private let cornerRadius: CGFloat = 16
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Collection Image Background (fixed to card bounds)
            if let firstImageUrl = collection.imageUrls.first, !firstImageUrl.isEmpty {
                WebImage(url: URL(string: firstImageUrl))
                    .resizable()
                    .scaledToFill()
                    .frame(height: cardHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "photo"))
            }
            
            // Dark overlay (fills card)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.black.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            HStack {
                Text(collection.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.leading, 24)
                
                Spacer()
                
                Circle()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 35, height: 35)
                    .overlay(
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .padding(.trailing, 24)
            }
        }
        .frame(height: cardHeight)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
        .onTapGesture {
            router.push(to: .carouselProducts(productIds: collection.productIds, title: collection.name))
        }
    }
}

#Preview {
    CategoriesView()
        .environmentObject(AppRouter())
}
