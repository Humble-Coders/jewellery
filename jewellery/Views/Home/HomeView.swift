import SwiftUI
import AVKit
import SDWebImageSwiftUI
import Combine

private let homeHeaderColor = Color(red: 0.77, green: 0.62, blue: 0.62)
private let homeHeaderForeground = Color(red: 0.93, green: 0.87, blue: 0.79)

// MARK: - Animated Search Placeholder
struct AnimatedSearchPlaceholder: View {
    let categories: [String]
    
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    private let timer = Timer.publish(every: 2.5, on: .main, in: .common).autoconnect()
    
    private var currentCategory: String {
        guard !categories.isEmpty else { return "categories" }
        return categories[currentIndex]
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Text("Search by ")
                .font(.system(size: 16))
                .foregroundColor(.gray.opacity(0.8))
            
            ZStack(alignment: .leading) {
                Text(currentCategory)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .offset(y: offset)
                    .opacity(opacity)
            }
            .frame(height: 20)
            .clipped()
        }
        .onReceive(timer) { _ in
            guard categories.count > 1 else { return }
            withAnimation(.easeIn(duration: 0.3)) {
                offset = -15
                opacity = 0
            }
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                currentIndex = (currentIndex + 1) % categories.count
                offset = 15
                withAnimation(.easeOut(duration: 0.3)) {
                    offset = 0
                    opacity = 1
                }
            }
        }
    }
}

// MARK: - Animated Text Carousel
struct AnimatedTextCarousel: View {
    private let texts = [
        "Elegant Jewels",
        "Timeless Beauty",
        "Precious Moments",
        "Sparkling Elegance",
        "Refined Luxury",
        "Classic Sophistication",
        "Radiant Glamour",
        "Exquisite Craftsmanship"
    ]
    
    @State private var currentIndex = 0
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    private let accentColor = Color(red: 0.54, green: 0.42, blue: 0.42) // #896C6C
    
    var body: some View {
        ZStack {
            Text(texts[currentIndex])
                .font(.system(size: 22, weight: .bold, design: .serif))
                .foregroundColor(accentColor)
                .offset(y: offset)
                .opacity(opacity)
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .clipped()
        .onReceive(timer) { _ in
            // Slide up + fade out
            withAnimation(.easeIn(duration: 0.4)) {
                offset = -30
                opacity = 0
            }
            // After exit animation, swap text and slide in from bottom
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                currentIndex = (currentIndex + 1) % texts.count
                offset = 30
                withAnimation(.easeOut(duration: 0.4)) {
                    offset = 0
                    opacity = 1
                }
            }
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var videoPlayerVM = VideoPlayerViewModel()
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var isSearchPresented = false
    
    private var homeGradient: some View {
        LinearGradient(
            stops: [
                Gradient.Stop(color: Color(red: 0.77, green: 0.62, blue: 0.62), location: 0),
                Gradient.Stop(color: Color(red: 0.9, green: 0.75, blue: 0.71), location: 0.2),
                Gradient.Stop(color: Color(red: 0.93, green: 0.87, blue: 0.79), location: 0.5),
                Gradient.Stop(color: .white, location: 0.85)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var scrollableBackgroundGradient: some View {
        VStack(spacing: 0) {
            LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.77, green: 0.62, blue: 0.62), location: 0.08),
                    Gradient.Stop(color: Color(red: 0.9, green: 0.75, blue: 0.71), location: 0.28),
                    Gradient.Stop(color: Color(red: 0.93, green: 0.87, blue: 0.79), location: 0.58),
                    Gradient.Stop(color: .white, location: 0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 349)
            
            Color.white
        }
    }
    
    private var mainScrollContent: some View {
        Group {
            if isSearchPresented {
                if viewModel.isSearchActive {
                    searchResultsContent
                } else {
                    searchEmptyState
                }
            } else {
                ScrollView {
                    ZStack(alignment: .top) {
                        scrollableBackgroundGradient
                        
                        LazyVStack(spacing: 0) {
                            promotionalBanner
                            nativeSearchBar
                            categoriesSection
                            recentlyViewedSection
                                .background(Color.white)
                            preciousMomentsSection
                                .background(Color.white)
                            finestCollectionsSection
                                .background(Color.white)
                            collectionsSection
                                .background(Color.white)
                            testimonialsSection
                                .background(Color.white)
                            editorialSection
                                .background(Color.white)
                        }
                    }
                }
                .scrollDisabled(router.showSidebar)
                .scrollContentBackground(.hidden)
            }
        }
    }
    
    private var searchEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3))
            Text("Search for categories")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }
    
    private var searchResultsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if !viewModel.filteredCategories.isEmpty {
                    ForEach(viewModel.filteredCategories) { category in
                        Button {
                            isSearchPresented = false
                            viewModel.searchQuery = ""
                            router.push(to: .categoryProducts(categoryId: category.id, categoryName: category.name))
                        } label: {
                            HStack(spacing: 14) {
                                if !category.imageUrl.isEmpty, let url = URL(string: category.imageUrl) {
                                    WebImage(url: url)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color(red: 0.77, green: 0.62, blue: 0.62).opacity(0.15))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            Image(systemName: "tag.fill")
                                                .font(.system(size: 16))
                                                .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                                        )
                                }
                                
                                Text(category.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.6))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                        }
                        
                        Divider()
                            .padding(.leading, 82)
                            .padding(.trailing, 20)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.4))
                        Text("No categories match \"\(viewModel.searchQuery)\"")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
            }
            .padding(.top, 8)
        }
        .background(Color.white)
    }
    
    private var promotionalBanner: some View {
        Group {
            if let homeTopUrl = viewModel.homeTopImageUrl {
                WebImage(url: URL(string: homeTopUrl))
                    .resizable()
                    .scaledToFit()
                    .frame(height: 243)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 243)
                    .overlay(ProgressView())
            }
        }
        .offset(y: 15)
        .onAppear { Task { await viewModel.loadHomeTopIfNeeded() } }
    }
    
    private var nativeSearchBar: some View {
        Button {
            withAnimation(.easeOut(duration: 0.25)) {
                isSearchPresented = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                AnimatedSearchPlaceholder(
                    categories: viewModel.categories.map { $0.name }
                )
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
        .padding(.top, -10)
        .padding(.bottom, Theme.Spacing.sm)
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if viewModel.categories.isEmpty {
                Text("Loading categories...")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 17)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    InfiniteCategoryScroll(categories: viewModel.categories, router: router)
                }
                .frame(height: 90)
            }
        }
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.lg)
    }
    
    // MARK: - Recently Viewed Section
    @ViewBuilder
    private var recentlyViewedSection: some View {
        // Only show section if there are products OR if loading for the first time
        if !viewModel.recentlyViewedProducts.isEmpty || viewModel.isLoadingRecentlyViewed {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Section Header
                HStack(spacing: 12) {
                    LinearGradient(
                        colors: [Color.clear, Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    
                    Text("Recently Viewed")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                        .fixedSize()
                    
                    LinearGradient(
                        colors: [Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.sm)
                
                // Products or Loading
                if viewModel.isLoadingRecentlyViewed && viewModel.recentlyViewedProducts.isEmpty {
                    // Show loading ONLY if list is empty
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                } else if !viewModel.recentlyViewedProducts.isEmpty {
                    // Show products in horizontal scroll
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(viewModel.recentlyViewedProducts.prefix(10)) { product in
                                RecentlyViewedProductCard(product: product, router: router)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    //.padding(.bottom, Theme.Spacing.md)
                }
            }
            .padding(.bottom, Theme.Spacing.lg)
        }
    }
    
    private var preciousMomentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            AnimatedTextCarousel()
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)
            
            if let videoHeader = viewModel.videoHeader, !videoHeader.link.isEmpty {
                VideoPlayerView(videoURL: videoHeader.link, externalViewModel: videoPlayerVM)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.lg)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .aspectRatio(16/9, contentMode: .fit)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .overlay(ProgressView())
            }
        }
        .padding(.bottom, Theme.Spacing.md)
        .onAppear { viewModel.loadVideoHeaderIfNeeded() }
    }
    
    @ViewBuilder
    private var finestCollectionsSection: some View {
        if !viewModel.carouselItems.isEmpty {
            VStack(spacing: Theme.Spacing.md) {
                HStack(spacing: 12) {
                    LinearGradient(
                        colors: [Color.clear, Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                    
                    Text("Our Finest Collections")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                        .fixedSize()
                    
                    LinearGradient(
                        colors: [Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 1)
                }
                .padding(.horizontal, 24)
                .padding(.top, Theme.Spacing.xl)
                .padding(.bottom, -20)
                
                TabView {
                    ForEach(viewModel.carouselItems) { item in
                        finestCollectionItem(item)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .frame(height: 250)
                .onAppear {
                    UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(red: 146/255, green: 80/255, blue: 13/255, alpha: 1.0)
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor(red: 146/255, green: 111/255, blue: 111/255, alpha: 0.3)
                }
            }
            .padding(.bottom, Theme.Spacing.md)
        }
    }
    
    private func finestCollectionItem(_ item: CarouselItem) -> some View {
        HStack(spacing: 24) {
            if !item.imageUrl.isEmpty {
                WebImage(url: URL(string: item.imageUrl), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                })
                .frame(width: 150, height: 150)
                .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(red: 146/255, green: 80/255, blue: 13/255))
                
                Text(item.subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 146/255, green: 80/255, blue: 13/255))
                    .lineLimit(2)
                
                HStack(spacing: 12) {
                    Button(action: {
                        router.push(to: .carouselProducts(productIds: item.productIds, title: item.title))
                    }) {
                        Text("Shop Now")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color(red: 146/255, green: 80/255, blue: 13/255))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(red: 146/255, green: 80/255, blue: 13/255), lineWidth: 1)
                            )
                    }
                    
                    Button(action: {
                        router.push(to: .carouselProducts(productIds: item.productIds, title: item.title))
                    }) {
                        Circle()
                            .fill(Color(red: 146/255, green: 80/255, blue: 13/255))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 24)
    }
    
    @ViewBuilder
    private var collectionsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: 12) {
                LinearGradient(
                    colors: [Color.clear, Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                
                Text("Collections")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                    .fixedSize()
                
                LinearGradient(
                    colors: [Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
            .padding(.bottom, 20)
            
            if !viewModel.collections.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.collections) { collection in
                            collectionCard(collection)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 120)
                    .overlay(ProgressView())
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .onAppear { viewModel.loadCollectionsIfNeeded() }
    }
    
    private func collectionCard(_ collection: ThemedCollection) -> some View {
        VStack(spacing: 12) {
            Text(collection.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color(red: 93/255, green: 93/255, blue: 93/255))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            collectionImages(collection.imageUrls)
            
            Text(collection.description)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 93/255, green: 93/255, blue: 93/255))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            Button(action: {
                router.push(to: .carouselProducts(productIds: collection.productIds, title: collection.name))
            }) {
                Text("See All Products")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 146/255, green: 111/255, blue: 111/255))
                    .cornerRadius(30)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 295)
        .background(Color(red: 0.97, green: 0.95, blue: 0.91))
        .cornerRadius(16)
        .padding(.bottom, Theme.Spacing.md)
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 4)
    }
    
    private func collectionImages(_ imageUrls: [String]) -> some View {
        HStack(spacing: 8) {
            let imageCount = min(imageUrls.count, 3)
            
            if imageCount == 2 {
                Spacer().frame(width: 46.5)
            }
            
            ForEach(Array(imageUrls.prefix(3).enumerated()), id: \.offset) { index, imageUrl in
                if !imageUrl.isEmpty {
                    WebImage(url: URL(string: imageUrl), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }, placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    })
                    .frame(width: 80, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(width: 85, height: 100)
                }
            }
            
            if imageCount == 2 {
                Spacer().frame(width: 46.5)
            }
        }
        .frame(height: 100)
        .padding(.horizontal, 10)
    }
    
    private var testimonialsSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack(spacing: 12) {
                LinearGradient(
                    colors: [Color.clear, Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                
                Text("Customer Testimonials")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                    .fixedSize()
                
                LinearGradient(
                    colors: [Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
            .padding(.bottom, 15)
            .padding(.top, 20)
            
            if !viewModel.testimonials.isEmpty {
                TestimonialCarousel(testimonials: viewModel.testimonials)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(ProgressView())
            }
        }
        .padding(.bottom, Theme.Spacing.xl)
        .onAppear { viewModel.loadTestimonialsIfNeeded() }
    }
    
    private var editorialSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(spacing: 16) {
                LinearGradient(
                    colors: [Color.clear, Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
                
                Text("Editorial")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                    .fixedSize()
                
                LinearGradient(
                    colors: [Color(red: 146/255, green: 111/255, blue: 111/255).opacity(0.3), Color.clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 1)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.lg)
            
            if !viewModel.editorialImages.isEmpty {
                ExactPatternEditorialGrid(images: viewModel.editorialImages, router: router)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(ProgressView())
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, Theme.Spacing.xl)
        .onAppear { viewModel.loadEditorialIfNeeded() }
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    homeHeaderColor
                        .frame(height: geo.size.height * 0.6)
                    Color.white
                        .frame(height: geo.size.height * 0.4)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                mainScrollContent
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
        .navigationTitle("Gagan Jewellers")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(homeHeaderColor, for: .navigationBar)
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
                Text("Gagan Jewellers")
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
        .onAppear {
            router.currentRoute = .home
            router.selectedTab = .home
            
            // Always load on appear (uses cache + background refresh strategy)
            viewModel.loadPriorityData()
            
            // Preload wishlist IDs into memory (avoids per-card Firestore reads)
            Task { await WishlistService.shared.loadWishlistIds() }
            
            // Refresh recently viewed products every time we return to home
            viewModel.refreshRecentlyViewed()
            
            // Retry failed sections if network is available
            if networkMonitor.isConnected {
                viewModel.retryFailedSections()
            }
        }
        .refreshable {
            viewModel.refreshData()
        }
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if isConnected {
                // Network came back - retry failed loads
                viewModel.retryFailedSections()
            }
        }
        .animatedSearchBar(
            text: Binding(
                get: { viewModel.searchQuery },
                set: { viewModel.searchQuery = $0 }
            ),
            isPresented: $isSearchPresented,
            placeholder: "Search categories..."
        )
        .onChange(of: isSearchPresented) { presented in
            if !presented {
                viewModel.searchQuery = ""
            }
        }
    }
}

// MARK: - Supporting Views

struct TestimonialCard: View {
    let testimonial: CustomerTestimonial
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            if !testimonial.imageUrl.isEmpty {
                WebImage(url: URL(string: testimonial.imageUrl), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                })
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
                    .overlay(Image(systemName: "person.circle"))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let age = testimonial.age {
                    Text("\(testimonial.name), \(age)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                } else {
                    Text(testimonial.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Text(testimonial.testimonial)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(4)
            }
            .frame(width: 150)
        }
    }
}

struct ExactPatternEditorialGrid: View {
    let images: [EditorialImage]
    let router: AppRouter
    
    var body: some View {
        VStack(spacing: 12) {
            let patternSize = 10
            let completePatterns = images.count / patternSize
            let remainingItems = images.count % patternSize
            
            // Create complete patterns
            ForEach(0..<completePatterns, id: \.self) { patternIndex in
                let patternStartIndex = patternIndex * patternSize
                let patternItems = Array(images[patternStartIndex..<min(patternStartIndex + patternSize, images.count)])
                
                if patternItems.count >= patternSize {
                VStack(spacing: 12) {
                    // Row 1: Large left + 2 small right
                    HStack(alignment: .top, spacing: 12) {
                        EditorialCard(image: patternItems[0], router: router)
                            .frame(height: 320)
                        
                        VStack(spacing: 12) {
                            EditorialCard(image: patternItems[1], router: router)
                                .frame(height: 154)
                            EditorialCard(image: patternItems[2], router: router)
                                .frame(height: 154)
                        }
                    }
                    
                    // Row 2: Two equal items
                    HStack(spacing: 12) {
                        EditorialCard(image: patternItems[3], router: router)
                            .frame(height: 200)
                        EditorialCard(image: patternItems[4], router: router)
                            .frame(height: 200)
                    }
                    
                    // Row 3: 2 small left + Large right
                    HStack(alignment: .top, spacing: 12) {
                        VStack(spacing: 12) {
                            EditorialCard(image: patternItems[5], router: router)
                                .frame(height: 154)
                            EditorialCard(image: patternItems[6], router: router)
                                .frame(height: 154)
                        }
                        
                        EditorialCard(image: patternItems[7], router: router)
                            .frame(height: 320)
                    }
                    
                    // Row 4: Two equal items
                    HStack(spacing: 12) {
                        EditorialCard(image: patternItems[8], router: router)
                            .frame(height: 200)
                        EditorialCard(image: patternItems[9], router: router)
                            .frame(height: 200)
                    }
                }
                } // guard patternItems.count >= patternSize
            }
            
            // Handle remaining items
            if remainingItems > 0 {
                let remainingItemsList = Array(images.suffix(remainingItems))
                let pairs = stride(from: 0, to: remainingItemsList.count, by: 2).map {
                    Array(remainingItemsList[$0..<min($0 + 2, remainingItemsList.count)])
                }
                
                ForEach(Array(pairs.enumerated()), id: \.offset) { _, pair in
                    HStack(spacing: 12) {
                        EditorialCard(image: pair[0], router: router)
                            .frame(height: 200)
                        
                        if pair.count > 1 {
                            EditorialCard(image: pair[1], router: router)
                                .frame(height: 200)
                        } else {
                            Color.clear
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct EditorialCard: View {
    let image: EditorialImage
    let router: AppRouter
    
    var body: some View {
        GeometryReader { geometry in
            if !image.imageUrl.isEmpty {
                WebImage(url: URL(string: image.imageUrl), content: { image in
                    image
                        .resizable()
                        .scaledToFill()
                }, placeholder: {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(ProgressView())
                })
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .onTapGesture {
                    if let productId = image.productId {
                        router.push(to: .itemDetail(productId: productId))
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(Image(systemName: "photo"))
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
        }
    }
}

// MARK: - Video Skeleton Loading
struct VideoSkeletonLoading: View {
    @State private var isAnimating = false
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: isAnimating ? 400 : -400)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .onAppear {
                withAnimation(
                    Animation
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Enhanced Video Player
struct VideoPlayerView: View {
    let videoURL: String
    @ObservedObject var externalViewModel: VideoPlayerViewModel
    
    init(videoURL: String, externalViewModel: VideoPlayerViewModel) {
        self.videoURL = videoURL
        self.externalViewModel = externalViewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if externalViewModel.isLoading && !externalViewModel.hasError {
                    VideoSkeletonLoading()
                } else if externalViewModel.hasError {
                    Rectangle()
                        .fill(Color.gray.opacity(0.15))
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 32))
                                    .foregroundColor(.gray)
                                Text("Video unavailable")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let player = externalViewModel.player {
                    PlayerLayerView(player: player)
                        .aspectRatio(16/9, contentMode: .fit)
                        .frame(width: geometry.size.width)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .allowsHitTesting(false)
                        .overlay(
                            Group {
                                if externalViewModel.isBuffering {
                                    ZStack {
                                        Color.black.opacity(0.3)
                                        ProgressView()
                                            .tint(.white)
                                    }
                                }
                            }
                        )
                }
            }
        }
        .aspectRatio(16/9, contentMode: .fit)
        .onAppear {
            externalViewModel.setupPlayer(url: videoURL)
        }
        .onDisappear {
            externalViewModel.pause()
        }
    }
}

// MARK: - AVPlayerLayer UIViewRepresentable (no controls)
private struct PlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.playerLayer.player = player
    }
    
    class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - Video Player ViewModel
@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var isLoading = true
    @Published var isBuffering = false
    @Published var hasError = false
    
    private var playerItem: AVPlayerItem?
    private var statusObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    private var playbackEndObserver: NSObjectProtocol?
    private var timeControlStatusObserver: NSKeyValueObservation?
    
    func pause() {
        player?.pause()
    }
    
    func setupPlayer(url: String) {
        // If player already exists, just resume playback
        if player != nil {
            player?.play()
            return
        }
        
        guard let videoURL = URL(string: url) else {
            hasError = true
            isLoading = false
            return
        }
        
        let asset = AVURLAsset(url: videoURL)
        playerItem = AVPlayerItem(asset: asset)
        
        guard let playerItem = playerItem else {
            hasError = true
            isLoading = false
            return
        }
        
        // Create player
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = true
        player?.automaticallyWaitsToMinimizeStalling = true
        
        // Observe player status
        statusObserver = playerItem.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                switch item.status {
                case .readyToPlay:
                    self?.isLoading = false
                    self?.hasError = false
                    self?.player?.play()
                case .failed:
                    self?.isLoading = false
                    self?.hasError = true
                    #if DEBUG
                    print("❌ Video player error: \(item.error?.localizedDescription ?? "Unknown error")")
                    #endif
                case .unknown:
                    self?.isLoading = true
                @unknown default:
                    break
                }
            }
        }
        
        // Observe buffering state
        bufferObserver = playerItem.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                self?.isBuffering = !item.isPlaybackLikelyToKeepUp && item.status == .readyToPlay
            }
        }
        
        // Observe time control status for better buffering detection
        timeControlStatusObserver = player?.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            Task { @MainActor in
                if player.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                    self?.isBuffering = true
                } else if player.timeControlStatus == .playing {
                    self?.isBuffering = false
                }
            }
        }
        
        // Setup looping
        setupLooping()
    }
    
    private func setupLooping() {
        playbackEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.play()
        }
    }
    
    func cleanup() {
        statusObserver?.invalidate()
        statusObserver = nil
        bufferObserver?.invalidate()
        bufferObserver = nil
        timeControlStatusObserver?.invalidate()
        timeControlStatusObserver = nil
        
        if let observer = playbackEndObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        playbackEndObserver = nil
        
        player?.pause()
        player = nil
        playerItem = nil
    }
    
    deinit {
        let s = statusObserver
        let b = bufferObserver
        let t = timeControlStatusObserver
        let p = playbackEndObserver
        s?.invalidate()
        b?.invalidate()
        t?.invalidate()
        if let p { NotificationCenter.default.removeObserver(p) }
    }
}

struct InfiniteScrollView<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let spacing: CGFloat
    let content: (Item) -> Content
    
    @State private var offset: CGFloat = 0
    @State private var lastInteractionTime = Date()
    @State private var timer: Timer?
    
    init(items: [Item], spacing: CGFloat = 19, @ViewBuilder content: @escaping (Item) -> Content) {
        self.items = items
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing) {
                        ForEach(0..<3) { copyIndex in
                            ForEach(items) { item in
                                content(item)
                                    .id("\(item.id)-\(copyIndex)")
                            }
                        }
                    }
                    .padding(.horizontal, 17)
                }
                .onAppear {
                    startAutoScroll()
                }
                .onDisappear {
                    timer?.invalidate()
                }
            }
        }
        .frame(height: 90)
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
            
            if timeSinceLastInteraction > 2.0 {
                offset -= 0.5
                
                let itemWidth: CGFloat = 66 + spacing
                let totalWidth = itemWidth * CGFloat(items.count)
                
                if abs(offset) >= totalWidth {
                    offset = 0
                }
            }
        }
    }
}

struct InfiniteCategoryScroll: View {
    let categories: [Category]
    let router: AppRouter
    
    @State private var offset: CGFloat = 0
    @State private var timer: Timer?
    
    var body: some View {
        let infiniteCategories = categories + categories + categories
        
        HStack(spacing: 19) {
            ForEach(Array(infiniteCategories.enumerated()), id: \.offset) { index, category in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#eeddca"))
                            .frame(width: 66, height: 66)
                        
                        if !category.imageUrl.isEmpty {
                            WebImage(url: URL(string: category.imageUrl), content: { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            }, placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .overlay(ProgressView())
                            })
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                        } else {
                            VStack {
                                Image(systemName: "photo")
                                    .font(.system(size: 20))
                                Text(category.name)
                                    .font(.system(size: 10))
                            }
                        }
                    }
                    .overlay(Circle().stroke(Theme.primaryColor, lineWidth: 1))
                    
                    Text(category.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Theme.primaryColor)
                        .lineLimit(1)
                }
                .frame(width: 66)
                .onTapGesture {
                    #if DEBUG
                    print("🔗 Navigating to categoryProducts - categoryId: '\(category.id)', categoryName: '\(category.name)'")
                    #endif
                    router.push(to: .categoryProducts(categoryId: category.id, categoryName: category.name))
                }
            }
        }
        .padding(.horizontal, 17)
        .offset(x: offset)
        .onAppear {
            startAutoScroll()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            offset -= 0.5
            
            let itemWidth: CGFloat = 85 // 66 + 19 spacing
            let totalWidth = itemWidth * CGFloat(categories.count)
            
            if abs(offset) >= totalWidth {
                offset = 0
            }
        }
    }
}

struct TestimonialCarousel: View {
    let testimonials: [CustomerTestimonial]
    @State private var currentIndex: Int = 0
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(testimonials.enumerated()), id: \.element.id) { index, testimonial in
                                GeometryReader { cardGeometry in
                                    let midX = cardGeometry.frame(in: .global).midX
                                    let screenMidX = geometry.size.width / 2
                                    let offset = midX - screenMidX
                                    let scale = 1 - (abs(offset) / geometry.size.width) * 0.2
                                    let opacity = 1 - (abs(offset) / geometry.size.width) * 0.15
                                    
                                    VStack(spacing: 16) {
                                        if !testimonial.imageUrl.isEmpty {
                                            WebImage(url: URL(string: testimonial.imageUrl), content: { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            }, placeholder: {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(Color.gray.opacity(0.2))
                                                    .overlay(ProgressView())
                                            })
                                            .frame(width: 280, height: 200)
                                            .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                        
                                        if let age = testimonial.age {
                                            Text("\(testimonial.name), \(age)")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(Color(red: 93/255, green: 93/255, blue: 93/255))
                                        } else {
                                            Text(testimonial.name)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(Color(red: 93/255, green: 93/255, blue: 93/255))
                                        }
                                        
                                        Text(testimonial.testimonial)
                                            .font(.system(size: 12))
                                            .foregroundColor(Color(red: 93/255, green: 93/255, blue: 93/255))
                                            .multilineTextAlignment(.center)
                                            .lineLimit(3)
                                            .frame(width: 280)
                                    }
                                    .frame(width: 230)
                                    .scaleEffect(scale)
                                    .opacity(opacity)
                                    .onChange(of: abs(offset)) { newValue in
                                        if newValue < 50 {
                                            currentIndex = index
                                        }
                                    }
                                }
                                .frame(width: 280, height: 320)
                                .id(index)
                            }
                        }
                        .padding(.horizontal, (geometry.size.width - 280) / 2)
                    }
                }
            }
            .frame(height: 320)
            
            HStack(spacing: 8) {
                ForEach(0..<testimonials.count, id: \.self) { index in
                    Circle()
                        .fill(index == currentIndex ? Color(red: 146/255, green: 80/255, blue: 13/255) : Color(red: 212/255, green: 184/255, blue: 150/255))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Recently Viewed Product Card
struct RecentlyViewedProductCard: View {
    let product: Product
    let router: AppRouter
    @State private var isFavorite = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Product Image with Wishlist Button
            ZStack(alignment: .topTrailing) {
                if let firstImageUrl = product.imageUrls.first, !firstImageUrl.isEmpty {
                    WebImage(url: URL(string: firstImageUrl), content: { image in
                        image
                            .resizable()
                            .scaledToFill()
                    }, placeholder: {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .overlay(ProgressView())
                    })
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 160, height: 160)
                        .overlay(Image(systemName: "photo"))
                }
                
                // Wishlist Button
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
                            }
                        }
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 16))
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // Product Name
            Text(product.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Product Price
            Text(product.formattedPrice)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
                
        }
        .frame(width: 160)
        .background(Color(red: 0.93, green: 0.87, blue: 0.79))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.15), radius: 0, x: 0, y: 0)
        .onTapGesture {
            router.push(to: .itemDetail(productId: product.id))
        }
        .task {
            isFavorite = await WishlistService.shared.isInWishlistAsync(productId: product.id)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppRouter())
        .environmentObject(NetworkMonitor.shared)
}
