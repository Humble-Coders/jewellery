import Foundation
import Combine

@MainActor
class BaseViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    var cancellables = Set<AnyCancellable>()
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    deinit {
        cancellables.removeAll()
    }
}
