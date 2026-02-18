import Foundation

struct Constants {
    // MARK: - Theme Colors
    struct Colors {
        static let primary = "#896C6C"
        static let gold = "#D4AF37"
        static let lightBeige = "#F5F5DC"
        static let white = "#FFFFFF"
    }
    
    // MARK: - Navigation Routes (matching Android)
    struct Routes {
        static let splash = "splash"
        static let welcome = "welcome"
        static let login = "login"
        static let register = "register"
        static let home = "home"
        static let allProducts = "allProducts"
        static let categoryProducts = "categoryProducts"
        static let carouselProducts = "carouselProducts"
        static let itemDetail = "itemDetail"
        static let category = "category"
        static let collection = "collection"
        static let wishlist = "wishlist"
        static let orderHistory = "orderHistory"
        static let profile = "profile"
        static let storeInfo = "store_info"
        static let videoConsultation = "videoConsultation"
        static let myBookings = "myBookings"
        static let consultationHistory = "consultation_history"
    }
    
    // MARK: - Firestore Collections
    struct Firestore {
        static let users = "users"
        static let products = "products"
        static let categories = "categories"
        static let categoryProducts = "category_products"
        static let materials = "materials"
        static let themedCollections = "themed_collections"
        static let carouselItems = "carousel_items"
        static let featuredProducts = "featured_products"
        static let orders = "orders"
        static let storeInfo = "store_info"
        static let header = "Header"
        static let video = "Video"
        static let customerTestomonials = "CustomerTestomonials"
        static let editorial = "Editorial"
        static let bookings = "bookings"
        
        // Subcollections
        static let wishlist = "wishlist"
        static let recentlyViewed = "recently_viewed"
    }
    
    // MARK: - Pagination
    static let pageSize = 20
    
    // MARK: - Search
    static let searchDebounceDelay: TimeInterval = 0.3
    
    // MARK: - Video
    static let fallbackVideoURL = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
    
    // MARK: - Deep Links
    struct DeepLinks {
        static let customScheme = "gaganjewellers"
        static let githubPagesBase = "https://humble-coders.github.io/gagan-jewellers-links/"
        static let dynamicLinksBase = "https://gaganjewellers.page.link"
        
        /// Fallback URL (guaranteed valid at compile time)
        // swiftlint:disable:next force_unwrapping
        private static let fallbackURL = URL(string: "https://gaganjewellers.com")!
        
        /// Generates a shareable product URL with query parameters
        static func productShareURL(productId: String, name: String = "", price: String = "") -> URL {
            var components = URLComponents(string: githubPagesBase)
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "product", value: productId)
            ]
            if !name.isEmpty {
                queryItems.append(URLQueryItem(name: "name", value: name))
            }
            if !price.isEmpty {
                queryItems.append(URLQueryItem(name: "price", value: price))
            }
            components?.queryItems = queryItems
            return components?.url ?? URL(string: githubPagesBase) ?? fallbackURL
        }
        
        /// Generates the full share message for a product
        static func productShareMessage(name: String, price: String, url: URL) -> String {
            """
            ✨ Discover this exquisite \(name)!
            
            💎 Premium Quality | 💰 Price: \(price)
            
            🔗 View Details: \(url.absoluteString)
            
            ✨ Gagan Jewellers - Where Elegance Meets Craftsmanship
            """
        }
    }
    
    // MARK: - Animation Durations
    struct Animation {
        static let splashDuration: TimeInterval = 3.0
        static let textCarouselInterval: TimeInterval = 3.0
    }
}
