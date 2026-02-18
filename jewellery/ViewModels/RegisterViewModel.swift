import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import UIKit

@MainActor
class RegisterViewModel: BaseViewModel {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var showPassword: Bool = false
    @Published var showConfirmPassword: Bool = false
    
    private var router: AppRouter?
    
    func setRouter(_ router: AppRouter) {
        self.router = router
    }
    
    // MARK: - Validation
    var isNameValid: Bool {
        fullName.isNotBlank
    }
    
    var isEmailValid: Bool {
        email.isValidEmail
    }
    
    var isPhoneValid: Bool {
        phone.isEmpty || phone.isValidPhone
    }
    
    var isPasswordValid: Bool {
        password.count >= 6
    }
    
    var doPasswordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var canSignUp: Bool {
        isNameValid && isEmailValid && isPhoneValid && isPasswordValid && doPasswordsMatch
    }
    
    // MARK: - Sign Up with Email/Password
    func signUp() {
        guard canSignUp else {
            var errorMessage = "Please fix the following errors:\n"
            if !isNameValid { errorMessage += "• Name is required\n" }
            if !isEmailValid { errorMessage += "• Valid email is required\n" }
            if !isPhoneValid { errorMessage += "• Phone number must be 10 digits (if provided)\n" }
            if !isPasswordValid { errorMessage += "• Password must be at least 6 characters\n" }
            if !doPasswordsMatch { errorMessage += "• Passwords do not match\n" }
            
            handleError(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage]))
            return
        }
        
        isLoading = true
        clearError()
        
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password
        
        Auth.auth().createUser(withEmail: emailTrimmed, password: passwordTrimmed) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    // Handle specific Firebase errors
                    if let authError = error as NSError? {
                        if authError.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                            self.handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "This email is already registered. Please use a different email or sign in."]))
                        } else {
                            self.handleError(error)
                        }
                    } else {
                        self.handleError(error)
                    }
                    return
                }
                
                guard let user = result?.user else {
                    self.handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Registration failed"]))
                    return
                }
                
                // Create Firestore user document
                self.createFirestoreUser(user: user)
            }
        }
    }
    
    // MARK: - Create Firestore User Document
    private func createFirestoreUser(user: FirebaseAuth.User) {
        let db = FirebaseService.shared.db
        let userRef = db.collection(Constants.Firestore.users).document(user.uid)
        
        var userData: [String: Any] = [
            "name": fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            "email": email.trimmingCharacters(in: .whitespacesAndNewlines),
            "isGoogleSignIn": false,
            "createdAt": Timestamp(date: Date())
        ]
        
        if !phone.isEmpty {
            userData["phone"] = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        userRef.setData(userData) { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                // Verify user and navigate
                self.verifyUserAndNavigate(user: user)
            }
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle() {
        isLoading = true
        clearError()
        
        // Note: Google Sign-In requires additional setup
        // For now, show an error message that it needs to be configured
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.handleError(NSError(domain: "GoogleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In is not yet configured. Please use email/password sign up."]))
        }
        
        // TODO: Implement Google Sign-In when SDK is added
        // This should handle:
        // - "already registered with email" vs "already registered with Google" conflicts
        // - Create Firestore user doc with googleId and isGoogleSignIn = true
    }
    
    // MARK: - Verify User and Navigate
    private func verifyUserAndNavigate(user: FirebaseAuth.User) {
        user.getIDToken { [weak self] token, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                guard token != nil else {
                    self.handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Token verification failed"]))
                    return
                }
                
                // Navigate to home and clear back stack
                self.router?.navigate(to: .home, clearStack: true)
            }
        }
    }
}
