import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import UIKit

@MainActor
class LoginViewModel: BaseViewModel {
    @Published var emailOrPhone: String = ""
    @Published var password: String = ""
    @Published var showPassword: Bool = false
    @Published var passwordResetSent: Bool = false
    @Published var passwordResetMessage: String = ""
    
    private var router: AppRouter?
    
    func setRouter(_ router: AppRouter) {
        self.router = router
    }
    
    // MARK: - Validation
    var isEmailOrPhoneValid: Bool {
        emailOrPhone.isNotBlank
    }
    
    var isPasswordValid: Bool {
        password.count >= 6
    }
    
    var canLogin: Bool {
        isEmailOrPhoneValid && isPasswordValid
    }
    
    // MARK: - Login with Email/Password
    func signIn() {
        guard canLogin else {
            handleError(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please fill in all fields"]))
            return
        }
        
        isLoading = true
        clearError()
        
        // Determine if input is email or phone
        let email = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false
                
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                guard let user = result?.user else {
                    self.handleError(NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Login failed"]))
                    return
                }
                
                // Verify Firebase user and token
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
        // The actual implementation would require:
        // 1. Adding GoogleSignIn SDK via SPM
        // 2. Configuring URL scheme in Info.plist
        // 3. Setting up the client ID
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            self.handleError(NSError(domain: "GoogleSignIn", code: 0, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In is not yet configured. Please use email/password login."]))
        }
        
        // TODO: Implement Google Sign-In when SDK is added
        // This requires:
        // - Adding GoogleSignIn package dependency
        // - Configuring URL scheme
        // - Implementing the sign-in flow
    }
    
    // MARK: - Password Reset
    func sendPasswordReset() {
        guard isEmailOrPhoneValid else {
            handleError(NSError(domain: "Validation", code: 0, userInfo: [NSLocalizedDescriptionKey: "Please enter your email address"]))
            return
        }
        
        let email = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    self.handleError(error)
                    return
                }
                
                self.passwordResetSent = true
                self.passwordResetMessage = "Password reset email sent to \(email)"
            }
        }
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
