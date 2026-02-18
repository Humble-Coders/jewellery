import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class ProfileViewModel: BaseViewModel {
    @Published var user: User?
    @Published var showSignOutConfirmation = false
    @Published var showDeleteAccountConfirmation = false
    
    private var router: AppRouter?
    private var listenerRegistration: ListenerRegistration?
    
    func setRouter(_ router: AppRouter) {
        self.router = router
    }
    
    // MARK: - Fetch User Data
    func fetchUserData() {
        guard let currentUser = Auth.auth().currentUser else {
            // User is not logged in - this is okay, don't show error
            isLoading = false
            user = nil
            return
        }
        
        // Don't create duplicate listeners - if one already exists, skip
        guard listenerRegistration == nil else { return }
        
        isLoading = true
        clearError()
        
        // Set up real-time listener for user data
        listenerRegistration = FirebaseService.shared.db
            .collection("users")
            .document(currentUser.uid)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if let error = error {
                        self.handleError(error)
                        return
                    }
                    
                    guard let document = documentSnapshot, document.exists else {
                        self.handleError(NSError(domain: "Firestore", code: 0, userInfo: [NSLocalizedDescriptionKey: "User data not found"]))
                        return
                    }
                    
                    do {
                        self.user = try document.data(as: User.self)
                    } catch let decodingError as DecodingError {
                        #if DEBUG
                        print("❌ Decoding error: \(decodingError)")
                        #endif
                        
                        // Provide a more user-friendly error message
                        let errorMessage = "Unable to load profile data. Please contact support if this persists."
                        self.handleError(NSError(domain: "Profile", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
                    } catch {
                        #if DEBUG
                        print("❌ Profile error: \(error.localizedDescription)")
                        #endif
                        self.handleError(error)
                    }
                }
            }
    }
    
    // MARK: - Update User Data
    func updateUserProfile(name: String, phone: String, dateOfBirth: Date?) {
        guard let currentUser = Auth.auth().currentUser else {
            handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        isLoading = true
        clearError()
        
        var updateData: [String: Any] = [
            "name": name,
            "phone": phone
        ]
        
        // Add dateOfBirth if provided
        if let dateOfBirth = dateOfBirth {
            updateData["dateOfBirth"] = Timestamp(date: dateOfBirth)
        }
        
        FirebaseService.shared.db
            .collection("users")
            .document(currentUser.uid)
            .updateData(updateData) { [weak self] error in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.isLoading = false
                    
                    if let error = error {
                        self.handleError(error)
                    }
                }
            }
    }
    
    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            removeListener()
            router?.navigate(to: .welcome, clearStack: true)
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Delete Account
    func deleteAccount() {
        guard let currentUser = Auth.auth().currentUser else {
            handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        let userId = currentUser.uid
        isLoading = true
        clearError()
        
        // First delete user data from Firestore
        FirebaseService.shared.db
            .collection("users")
            .document(userId)
            .delete { [weak self] error in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        self.isLoading = false
                        self.handleError(error)
                        return
                    }
                    
                    // Get current user again for deletion
                    guard let authUser = Auth.auth().currentUser else {
                        self.isLoading = false
                        return
                    }
                    
                    // Then delete the Firebase Auth account
                    authUser.delete { [weak self] error in
                        Task { @MainActor in
                            guard let self = self else { return }
                            self.isLoading = false
                            
                            if let error = error {
                                self.handleError(error)
                                return
                            }
                            
                            self.removeListener()
                            self.router?.navigate(to: .welcome, clearStack: true)
                        }
                    }
                }
            }
    }
    
    // MARK: - Cleanup
    private func removeListener() {
        listenerRegistration?.remove()
        listenerRegistration = nil
    }
    
    deinit {
        // ListenerRegistration.remove() is thread-safe in Firebase SDK,
        // capture and remove outside MainActor isolation
        let registration = listenerRegistration
        registration?.remove()
    }
}
