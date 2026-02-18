import SwiftUI

struct Theme {
    // MARK: - Colors
    static let primaryColor = Color(hex: Constants.Colors.primary)
    static let goldColor = Color(hex: Constants.Colors.gold)
    static let lightBeigeColor = Color(hex: Constants.Colors.lightBeige)
    static let whiteColor = Color.white
    
    // MARK: - Gradients
    static let splashGradient = LinearGradient(
        colors: [.white, Color(hex: Constants.Colors.lightBeige)],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Typography
    struct Typography {
        static let brandSerif = Font.custom("Georgia", size: 42).bold()
        static let brandSans = Font.system(size: 18, weight: .medium)
        static let title = Font.system(size: 24, weight: .bold)
        static let headline = Font.system(size: 20, weight: .semibold)
        static let body = Font.system(size: 16, weight: .regular)
        static let caption = Font.system(size: 14, weight: .regular)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
    }
}

// MARK: - Color Extension for Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
