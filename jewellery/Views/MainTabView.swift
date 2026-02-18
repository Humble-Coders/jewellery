import SwiftUI

// MARK: - Rounded Corner Shape for specific corners
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct MainTabView: View {
    @EnvironmentObject var router: AppRouter
    
    private static let headerColor = UIColor(red: 0.77, green: 0.62, blue: 0.62, alpha: 1.0)
    
    init() {
        // Configure tab bar appearance early (before view renders)
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithDefaultBackground()
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = .black
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.black
        ]
        itemAppearance.selected.iconColor = Self.headerColor
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: Self.headerColor
        ]
        
        tabBarAppearance.stackedLayoutAppearance = itemAppearance
        tabBarAppearance.inlineLayoutAppearance = itemAppearance
        tabBarAppearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().unselectedItemTintColor = .black
        
        // Configure navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = Self.headerColor
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
    }
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            NavigationStack(path: $router.homePath) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        tabRouteView(for: route)
                    }
            }
            .tabItem {
                Label(MainTab.home.rawValue, systemImage: MainTab.home.icon)
            }
            .tag(MainTab.home)
            
            NavigationStack(path: $router.categoriesPath) {
                CategoriesView()
                    .navigationDestination(for: AppRoute.self) { route in
                        tabRouteView(for: route)
                    }
            }
            .tabItem {
                Label(MainTab.categories.rawValue, systemImage: MainTab.categories.icon)
            }
            .tag(MainTab.categories)
            
            NavigationStack(path: $router.favoritesPath) {
                WishlistView()
                    .navigationDestination(for: AppRoute.self) { route in
                        tabRouteView(for: route)
                    }
            }
            .tabItem {
                Label(MainTab.favorites.rawValue, systemImage: MainTab.favorites.icon)
            }
            .tag(MainTab.favorites)
            
            NavigationStack(path: $router.profilePath) {
                ProfileView()
                    .navigationDestination(for: AppRoute.self) { route in
                        tabRouteView(for: route)
                    }
            }
            .tabItem {
                Label(MainTab.profile.rawValue, systemImage: MainTab.profile.icon)
            }
            .tag(MainTab.profile)
        }
        .tint(Color(red: 0.77, green: 0.62, blue: 0.62))
        .onChange(of: router.selectedTab) { newTab in
            // When switching tabs, clear the destination tab's navigation stack
            // so it always shows the root view. Skip if router is mid-programmatic
            // navigation (indicated by suppressTabReset flag).
            guard !router.suppressTabReset else {
                router.suppressTabReset = false
                return
            }
            switch newTab {
            case .home: router.homePath = NavigationPath()
            case .categories: router.categoriesPath = NavigationPath()
            case .favorites: router.favoritesPath = NavigationPath()
            case .profile: router.profilePath = NavigationPath()
            }
        }
        .overlay {
            GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Dim background overlay
                if router.showSidebar {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                router.showSidebar = false
                            }
                        }
                        .transition(.opacity)
                }
                
                // Sidebar content
                if router.showSidebar {
                    NavigationStack {
                        NativeSidebarContent(isPresented: Binding(
                            get: { router.showSidebar },
                            set: { router.showSidebar = $0 }
                        ))
                    }
                    .frame(width: min(320, geometry.size.width * 0.85))
                    .background(Color(UIColor.systemBackground))
                    .clipShape(
                        RoundedCorner(radius: 24, corners: [.topRight])
                    )
                    .ignoresSafeArea(edges: .vertical)
                    .transition(.move(edge: .leading))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: router.showSidebar)
            }
        }
        .onAppear {
            router.showMainApp = true
        }
    }
    
    @ViewBuilder
    private func tabRouteView(for route: AppRoute) -> some View {
        switch route {
        case .allProducts(let metalId, let metalName):
            AllJewelleryView(initialMetalId: metalId, initialMetalName: metalName)
        case .categoryProducts(let categoryId, let categoryName):
            CategoryProductsView(categoryId: categoryId, categoryName: categoryName)
        case .carouselProducts(let productIds, let title):
            CollectionProductsView(productIds: productIds, collectionTitle: title)
        case .itemDetail(let productId):
            ProductDetailView(productId: productId)
        case .orderHistory:
            OrderHistoryView()
        case .storeInfo:
            StoreInfoView()
        case .videoConsultation:
            VideoConsultationView()
        case .myBookings:
            MyBookingsView()
        case .consultationHistory:
            Text("Consultation History Screen")
                .navigationTitle("History")
        default:
            EmptyView()
        }
    }
}
