import Foundation
import UIKit

/// Service to handle WhatsApp interactions
class WhatsAppService {
    static let shared = WhatsAppService()
    
    private init() {}
    
    /// Opens WhatsApp with a pre-filled message to the specified phone number
    /// Falls back to browser if WhatsApp is not installed
    /// - Parameters:
    ///   - phoneNumber: Phone number in international format (without + or spaces)
    ///   - message: Message text to pre-fill (will be URL-encoded)
    func openWhatsApp(phoneNumber: String, message: String) {
        // Clean phone number (remove any non-digit characters)
        let cleanedPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // URL-encode the message
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            #if DEBUG
            print("❌ Failed to encode WhatsApp message")
            #endif
            return
        }
        
        // Try WhatsApp app deep link first
        let whatsappAppURL = "whatsapp://send?phone=\(cleanedPhone)&text=\(encodedMessage)"
        
        if let url = URL(string: whatsappAppURL),
           UIApplication.shared.canOpenURL(url) {
            // WhatsApp is installed, open the app
            UIApplication.shared.open(url, options: [:]) { success in
                #if DEBUG
                if success {
                    print("✅ Opened WhatsApp app")
                } else {
                    print("⚠️ Failed to open WhatsApp app")
                }
                #endif
            }
        } else {
            // WhatsApp not installed, open in browser (WhatsApp Web)
            let whatsappWebURL = "https://wa.me/\(cleanedPhone)?text=\(encodedMessage)"
            
            if let url = URL(string: whatsappWebURL) {
                UIApplication.shared.open(url, options: [:]) { success in
                    #if DEBUG
                    if success {
                        print("✅ Opened WhatsApp Web in browser")
                    } else {
                        print("⚠️ Failed to open WhatsApp Web")
                    }
                    #endif
                }
            }
        }
    }
    
    /// Checks if WhatsApp is installed on the device
    var isWhatsAppInstalled: Bool {
        if let url = URL(string: "whatsapp://") {
            return UIApplication.shared.canOpenURL(url)
        }
        return false
    }
}
