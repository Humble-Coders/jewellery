import Foundation
import UIKit
import Combine

@MainActor
class StoreInfoViewModel: BaseViewModel {
    @Published var storeInfo: StoreInfo?
    @Published var currentTime: String = ""
    @Published var isOpenNow: Bool = false
    @Published var todayHours: String?
    
    private let service = StoreInfoService.shared
    private var currentTimeTimer: Timer?
    
    // MARK: - Lifecycle
    
    override init() {
        super.init()
        loadStoreData()
        startCurrentTimeTimer()
    }
    
    // MARK: - Load Data
    
    func loadStoreData() {
        isLoading = true
        clearError()
        
        Task {
            do {
                // Fetch store info (which includes store_hours)
                let fetchedInfo = try await service.fetchStoreInfo()
                
                storeInfo = fetchedInfo
                
                // Calculate today's status
                updateTodayStatus()
                
                isLoading = false
                
                #if DEBUG
                print("✅ Store data loaded successfully")
                #endif
            } catch {
                isLoading = false
                handleError(error)
                #if DEBUG
                print("❌ Failed to load store data: \(error.localizedDescription)")
                #endif
            }
        }
    }
    
    // MARK: - Today's Status
    
    private func updateTodayStatus() {
        guard let store = storeInfo else {
            isOpenNow = false
            todayHours = nil
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        todayHours = store.hoursForWeekday(weekday)
        isOpenNow = store.isCurrentlyOpen()
        updateCurrentTime()
    }
    
    // MARK: - Current Time
    
    private func startCurrentTimeTimer() {
        updateCurrentTime()
        
        // Update current time every minute
        let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentTime()
                self?.updateTodayStatus()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        currentTimeTimer = timer
    }
    
    deinit {
        currentTimeTimer?.invalidate()
        currentTimeTimer = nil
    }
    
    private func updateCurrentTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        currentTime = formatter.string(from: Date())
    }
    
    // MARK: - External Actions
    
    /// Open store location in maps app
    func openDirections() {
        guard let store = storeInfo else { return }
        
        // Try Apple Maps first
        let appleMapsUrl = "http://maps.apple.com/?ll=\(store.latitude),\(store.longitude)&q=\(urlEncode(store.name))"
        
        if let url = URL(string: appleMapsUrl), canOpen(url: url) {
            open(url: url)
        } else {
            // Fallback to Google Maps in browser
            let googleMapsUrl = "https://www.google.com/maps/search/?api=1&query=\(store.latitude),\(store.longitude)"
            if let url = URL(string: googleMapsUrl) {
                open(url: url)
            }
        }
    }
    
    /// Call primary phone number
    func callPrimaryPhone() {
        guard let store = storeInfo else { return }
        
        let sanitized = sanitizePhoneNumber(store.primaryPhone)
        let telUrl = "tel:\(sanitized)"
        
        if let url = URL(string: telUrl) {
            open(url: url)
        }
    }
    
    /// Call secondary phone number
    func callSecondaryPhone() {
        guard let store = storeInfo, let secondary = store.secondaryPhone else { return }
        
        let sanitized = sanitizePhoneNumber(secondary)
        let telUrl = "tel:\(sanitized)"
        
        if let url = URL(string: telUrl) {
            open(url: url)
        }
    }
    
    /// Open email client
    func sendEmail() {
        guard let store = storeInfo else { return }
        
        let mailtoUrl = "mailto:\(store.email)"
        
        if let url = URL(string: mailtoUrl) {
            open(url: url)
        }
    }
    
    /// Open WhatsApp with primary phone
    func openWhatsApp() {
        guard let store = storeInfo else { return }
        
        let sanitized = sanitizePhoneNumber(store.primaryPhone)
        let message = "Hello, I would like to inquire about your jewellery collection."
        let encodedMessage = urlEncode(message)
        
        // Try WhatsApp app first
        let whatsappUrl = "whatsapp://send?phone=\(sanitized)&text=\(encodedMessage)"
        
        if let url = URL(string: whatsappUrl), canOpen(url: url) {
            open(url: url)
        } else {
            // Fallback to WhatsApp Web
            let whatsappWebUrl = "https://wa.me/\(sanitized)?text=\(encodedMessage)"
            if let url = URL(string: whatsappWebUrl) {
                open(url: url)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Sanitize phone number (remove spaces, dashes, parentheses)
    private func sanitizePhoneNumber(_ phone: String) -> String {
        phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
    }
    
    /// URL encode a string
    private func urlEncode(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
    
    /// Check if a URL can be opened
    private func canOpen(url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }
    
    /// Open a URL
    private func open(url: URL) {
        UIApplication.shared.open(url)
    }
}
