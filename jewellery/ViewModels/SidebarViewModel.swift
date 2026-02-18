import Foundation
import Combine
import FirebaseFirestore

struct Material: Identifiable {
    let id: String
    let name: String
}

struct MetalRateType: Identifiable {
    let id: String
    let purity: String
    let rate: Double
}

struct MaterialWithRates: Identifiable {
    let id: String
    let name: String
    let types: [MetalRateType]
}

@MainActor
class SidebarViewModel: BaseViewModel {
    @Published var metals: [Material] = []
    @Published var categories: [Category] = []
    @Published var metalRates: [MaterialWithRates] = []
    @Published var ratesLastUpdated: Date?

    private let db = FirebaseService.shared.db
    
    /// Guard to prevent refetching every time the sidebar opens
    private var hasLoadedOnce = false
    
    func loadData() {
        guard !hasLoadedOnce else { return }
        Task {
            await loadCategories()
            await loadMaterialsAndRates()
            hasLoadedOnce = true
        }
    }
    
    /// Force a full refresh (bypasses the guard)
    func forceRefreshData() {
        hasLoadedOnce = false
        Task {
            await loadCategories()
            await loadMaterialsAndRates()
            hasLoadedOnce = true
        }
    }
    
    private func loadCategories() async {
        if let cached = await DataCache.shared.getCategories() {
            categories = cached
            return
        }
        do {
            try await fetchCategories()
            await DataCache.shared.setCategories(categories)
        } catch {
            handleError(error)
        }
    }
    
    /// Fetches categories - same logic as CategoriesViewModel
    private func fetchCategories() async throws {
        let snapshot = try await db.collection(Constants.Firestore.categories).getDocuments()
        var fetched: [Category] = []
        
        for document in snapshot.documents {
            let data = document.data()
            // Use full URL directly from Firestore (no Storage resolution needed)
            let imageUrl = CategoriesViewModel.extractImageUrl(from: data)
            fetched.append(Category(
                id: document.documentID,
                name: data["name"] as? String ?? "",
                imageUrl: imageUrl,
                description: data["description"] as? String
            ))
        }
        categories = fetched.sorted { $0.name < $1.name }
    }
    
    /// Fetches materials collection ONCE and extracts both metals list and rates
    private func loadMaterialsAndRates() async {
        do {
            let snapshot = try await db.collection(Constants.Firestore.materials).getDocuments()
            
            // Extract metals (simple name list)
            metals = snapshot.documents.compactMap { doc in
                guard let name = doc.data()["name"] as? String, !name.isEmpty else { return nil }
                return Material(id: doc.documentID, name: name)
            }.sorted { $0.name < $1.name }
            
            // Extract metal rates (with types/purities)
            var fetched: [MaterialWithRates] = []
            for doc in snapshot.documents {
                let data = doc.data()
                let name = (data["name"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty else { continue }
                
                var types: [MetalRateType] = []
                if let typesArray = data["types"] as? [[String: Any]] {
                    for (index, entry) in typesArray.enumerated() {
                        let purity = (entry["purity"] as? String ?? entry["Purity"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        let rateValue = entry["rate"] ?? entry["Rate"]
                        let rate = parseRate(from: rateValue)
                        types.append(MetalRateType(id: "\(doc.documentID)-\(index)", purity: purity, rate: rate))
                    }
                }
                
                if !types.isEmpty {
                    fetched.append(MaterialWithRates(id: doc.documentID, name: name, types: types))
                }
            }
            metalRates = fetched.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            ratesLastUpdated = Date()
        } catch {
            // Non-fatal - metals section can stay empty
        }
    }
    
    private func parseRate(from value: Any?) -> Double {
        guard let v = value else { return 0 }
        if let d = v as? Double { return d }
        if let i = v as? Int { return Double(i) }
        if let n = v as? NSNumber { return n.doubleValue }
        if let s = v as? String, let d = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) { return d }
        return 0
    }
}
