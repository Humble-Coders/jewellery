import SwiftUI
import Combine

enum AppRoute: Hashable {
    case splash
    case welcome
    case login
    case register
    case home
    case allProducts(metalId: String? = nil, metalName: String? = nil)
    case categoryProducts(categoryId: String, categoryName: String)
    case carouselProducts(productIds: [String], title: String)
    case itemDetail(productId: String)
    case category(categoryId: String)
    case collection(collectionId: String)
    case wishlist
    case orderHistory
    case profile
    case storeInfo
    case videoConsultation
    case myBookings
    case consultationHistory
    
    var routeName: String {
        switch self {
        case .splash: return Constants.Routes.splash
        case .welcome: return Constants.Routes.welcome
        case .login: return Constants.Routes.login
        case .register: return Constants.Routes.register
        case .home: return Constants.Routes.home
        case .allProducts: return Constants.Routes.allProducts
        case .categoryProducts: return Constants.Routes.categoryProducts
        case .carouselProducts: return Constants.Routes.carouselProducts
        case .itemDetail: return Constants.Routes.itemDetail
        case .category: return Constants.Routes.category
        case .collection: return Constants.Routes.collection
        case .wishlist: return Constants.Routes.wishlist
        case .orderHistory: return Constants.Routes.orderHistory
        case .profile: return Constants.Routes.profile
        case .storeInfo: return Constants.Routes.storeInfo
        case .videoConsultation: return Constants.Routes.videoConsultation
        case .myBookings: return Constants.Routes.myBookings
        case .consultationHistory: return Constants.Routes.consultationHistory
        }
    }
}

enum MainTab: String, CaseIterable {
    case home = "Home"
    case categories = "Categories"
    case favorites = "Favorites"
    case profile = "Profile"
    
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .categories: return "square.grid.2x2"
        case .favorites: return "heart.fill"
        case .profile: return "person.fill"
        }
    }
}

@MainActor
class AppRouter: ObservableObject {
    @Published var currentRoute: AppRoute = .splash
    @Published var navigationPath = NavigationPath()
    
    @Published var selectedTab: MainTab = .home
    @Published var homePath = NavigationPath()
    @Published var categoriesPath = NavigationPath()
    @Published var favoritesPath = NavigationPath()
    @Published var profilePath = NavigationPath()
    
    @Published var showMainApp: Bool = false
    @Published var showSidebar: Bool = false
    
    /// When true, the next tab change won't clear the navigation stack.
    /// Set by programmatic navigation that needs to push a route after switching tabs.
    var suppressTabReset = false
    
    func path(for tab: MainTab) -> NavigationPath {
        switch tab {
        case .home: return homePath
        case .categories: return categoriesPath
        case .favorites: return favoritesPath
        case .profile: return profilePath
        }
    }
    
    func navigate(to route: AppRoute, clearStack: Bool = false) {
        if showMainApp {
            switch route {
            case .home:
                showMainApp = true
                selectedTab = .home
                if clearStack { homePath = NavigationPath() }
                currentRoute = .home
            case .allProducts, .categoryProducts:
                showMainApp = true
                if clearStack {
                    // From sidebar: push onto home tab so bottom bar shows Home
                    suppressTabReset = true
                    selectedTab = .home
                    homePath = NavigationPath()
                    homePath.append(route)
                } else {
                    // From within the app (e.g. categories tab): push onto current tab
                    switch selectedTab {
                    case .home: homePath.append(route)
                    case .categories: categoriesPath.append(route)
                    case .favorites: favoritesPath.append(route)
                    case .profile: profilePath.append(route)
                    }
                }
            case .wishlist:
                showMainApp = true
                suppressTabReset = true
                selectedTab = .favorites
                if clearStack { favoritesPath = NavigationPath() }
            case .profile:
                showMainApp = true
                suppressTabReset = true
                selectedTab = .profile
                if clearStack { profilePath = NavigationPath() }
            case .orderHistory, .storeInfo, .videoConsultation, .myBookings, .consultationHistory:
                showMainApp = true
                if clearStack {
                    // From sidebar: push onto home tab so bottom bar shows Home
                    suppressTabReset = true
                    selectedTab = .home
                    homePath = NavigationPath()
                    homePath.append(route)
                } else {
                    // From within the app: push onto current tab
                    switch selectedTab {
                    case .home: homePath.append(route)
                    case .categories: categoriesPath.append(route)
                    case .favorites: favoritesPath.append(route)
                    case .profile: profilePath.append(route)
                    }
                }
            case .carouselProducts:
                showMainApp = true
                // Don't force tab switch - navigate within current tab's stack
                var path = self.path(for: selectedTab)
                if clearStack { path = NavigationPath() }
                path.append(route)
                switch selectedTab {
                case .home: homePath = path
                case .categories: categoriesPath = path
                case .favorites: favoritesPath = path
                case .profile: profilePath = path
                }
            case .itemDetail, .category, .collection:
                showMainApp = true
                var path = self.path(for: selectedTab)
                if clearStack { path = NavigationPath() }
                path.append(route)
                switch selectedTab {
                case .home: homePath = path
                case .categories: categoriesPath = path
                case .favorites: favoritesPath = path
                case .profile: profilePath = path
                }
            case .welcome:
                if clearStack {
                    showMainApp = false
                    navigationPath = NavigationPath()
                    navigationPath.append(AppRoute.welcome)
                }
            default:
                break
            }
        } else {
            if route == .home && clearStack {
                showMainApp = true
                navigationPath = NavigationPath()
            } else if route == .welcome && clearStack {
                showMainApp = false
            }
            if clearStack {
                navigationPath = NavigationPath()
            }
            if route != .home {
                currentRoute = route
                navigationPath.append(route)
            }
        }
    }
    
    func push(to route: AppRoute) {
        if showMainApp {
            switch selectedTab {
            case .home: homePath.append(route)
            case .categories: categoriesPath.append(route)
            case .favorites: favoritesPath.append(route)
            case .profile: profilePath.append(route)
            }
        } else {
            navigationPath.append(route)
        }
        currentRoute = route
    }
    
    func navigateBack() {
        if showMainApp {
            switch selectedTab {
            case .home:
                if !homePath.isEmpty { homePath.removeLast() }
            case .categories:
                if !categoriesPath.isEmpty { categoriesPath.removeLast() }
            case .favorites:
                if !favoritesPath.isEmpty { favoritesPath.removeLast() }
            case .profile:
                if !profilePath.isEmpty { profilePath.removeLast() }
            }
        } else {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
    }
    
    func pop() {
        navigateBack()
    }
    
    func tabForRoute(_ route: AppRoute) -> MainTab? {
        switch route {
        case .home: return .home
        case .wishlist: return .favorites
        case .profile: return .profile
        default: return nil
        }
    }
    
    func navigateToRoot() {
        if showMainApp {
            switch selectedTab {
            case .home: homePath = NavigationPath()
            case .categories: categoriesPath = NavigationPath()
            case .favorites: favoritesPath = NavigationPath()
            case .profile: profilePath = NavigationPath()
            }
            currentRoute = .home
        } else {
            navigationPath = NavigationPath()
            currentRoute = .home
        }
    }
}
