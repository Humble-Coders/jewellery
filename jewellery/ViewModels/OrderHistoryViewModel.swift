import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class OrderHistoryViewModel: BaseViewModel {
    @Published var orders: [Order] = []
    @Published var accountBalance: Double = 0
    
    private let db = FirebaseService.shared.db
    
    /// Guard to prevent refetching on every view appear
    private var hasLoadedOnce = false
    
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: accountBalance)) ?? "₹0.00"
    }
    
    /// Called on view appear. Only fetches once unless forced or data is empty.
    func loadData() {
        guard !hasLoadedOnce || orders.isEmpty else { return }
        forceLoadData()
    }
    
    /// Force a full reload (e.g. on pull-to-refresh or error retry)
    func forceLoadData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            orders = []
            accountBalance = 0
            return
        }
        isLoading = true
        clearError()
        Task {
            do {
                try await fetchAccountBalance(userId: userId)
                try await fetchOrders(customerId: userId)
                isLoading = false
                hasLoadedOnce = true
            } catch {
                isLoading = false
                handleError(error)
            }
        }
    }
    
    private func fetchAccountBalance(userId: String) async throws {
        let doc = try await db.collection(Constants.Firestore.users).document(userId).getDocument()
        if let data = doc.data(), let balance = data["balance"] as? Double {
            accountBalance = balance
        } else if let data = doc.data(), let balance = data["balance"] as? Int {
            accountBalance = Double(balance)
        } else {
            accountBalance = 0
        }
    }
    
    private func fetchOrders(customerId: String) async throws {
        let snapshot = try await db.collection(Constants.Firestore.orders)
            .whereField("customerId", isEqualTo: customerId)
            .getDocuments()
        
        var fetched: [Order] = []
        for document in snapshot.documents {
            let data = document.data()
            let createdAtMs: Int64
            if let i = data["createdAt"] as? Int { createdAtMs = Int64(i) }
            else if let i64 = data["createdAt"] as? Int64 { createdAtMs = i64 }
            else { createdAtMs = 0 }
            let createdAt = Date(timeIntervalSince1970: Double(createdAtMs) / 1000)
            let finalAmount = (data["finalAmount"] as? Double) ?? (data["finalAmount"] as? Int).map { Double($0) } ?? 0
            let order = Order(
                id: document.documentID,
                customerId: data["customerId"] as? String ?? "",
                createdAt: createdAt,
                finalAmount: finalAmount,
                invoiceUrl: data["invoiceUrl"] as? String,
                discountAmount: (data["discountAmount"] as? Double) ?? (data["discountAmount"] as? Int).map { Double($0) },
                discountPercent: data["discountPercent"] as? Double,
                gstAmount: (data["gstAmount"] as? Double) ?? (data["gstAmount"] as? Int).map { Double($0) },
                gstPercentage: data["gstPercentage"] as? Double,
                isGstIncluded: data["isGstIncluded"] as? Bool
            )
            fetched.append(order)
        }
        orders = fetched.sorted { $0.createdAt > $1.createdAt }
    }
    
    func refreshData() {
        forceLoadData()
    }
}
