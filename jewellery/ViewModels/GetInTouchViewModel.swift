import Foundation
import Combine

/// ViewModel to handle "Get in Touch" functionality
@MainActor
class GetInTouchViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    /// Fetches store info and opens WhatsApp
    /// This is a fire-and-forget operation that handles errors gracefully
    func openWhatsApp() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Fetch store info from Firestore
                let storeInfo = try await StoreInfoService.shared.fetchStoreInfo()
                
                // Get phone number - use primary phone
                let phoneNumber = storeInfo.primaryPhone
                let message = "Hello, I would like to inquire about your jewellery collection."
                
                WhatsAppService.shared.openWhatsApp(
                    phoneNumber: phoneNumber,
                    message: message
                )
                
                isLoading = false
                
                #if DEBUG
                print("📱 Opening WhatsApp to \(phoneNumber)")
                #endif
                
            } catch {
                isLoading = false
                errorMessage = "Could not connect to WhatsApp. Please try again."
                #if DEBUG
                print("❌ Error opening WhatsApp: \(error.localizedDescription)")
                #endif
            }
        }
    }
}
