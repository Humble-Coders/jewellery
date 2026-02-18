import SwiftUI

struct RegisterView: View {
    @StateObject private var viewModel = RegisterViewModel()
    @EnvironmentObject var router: AppRouter
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name
        case email
        case password
        case confirmPassword
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 12)
                    
                    // Crown Logo
                    Image("crown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Theme.goldColor)
                        .padding(.bottom, Theme.Spacing.sm)
                    
                    // Brand Typography
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("GAGAN")
                            .font(Theme.Typography.brandSerif)
                            .foregroundColor(.primary)
                            .tracking(4)
                        
                        Text("JEWELLERS")
                            .font(Theme.Typography.brandSans)
                            .foregroundColor(Theme.goldColor)
                            .tracking(6)
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                    
                    // Welcome Text
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Welcome")
                            .font(.system(size: 36, weight: .semibold, design: .default))
                            .foregroundColor(Theme.primaryColor)
                        
                        Text("Create a new account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#d9d9d9"))
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                    
                    // Input Fields
                    VStack(spacing: Theme.Spacing.md) {
                        // Name Field
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "person")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 20, height: 20)
                            
                            TextField("Name", text: $viewModel.fullName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.primaryColor)
                                .autocapitalization(.words)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .name)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                        
                        // Email/Phone Field
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "person")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 20, height: 20)
                            
                            TextField("Email id / Phone Number", text: $viewModel.email)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.primaryColor)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .email)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                        
                        // Password Field
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "lock")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 20, height: 20)
                            
                            if viewModel.showPassword {
                                TextField("Password", text: $viewModel.password)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.primaryColor)
                                    .focused($focusedField, equals: .password)
                            } else {
                                SecureField("Password", text: $viewModel.password)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.primaryColor)
                                    .focused($focusedField, equals: .password)
                            }
                            
                            Button(action: {
                                viewModel.showPassword.toggle()
                            }) {
                                Image(systemName: viewModel.showPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Theme.primaryColor)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                        
                        // Confirm Password Field (required by documentation)
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "lock")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 20, height: 20)
                            
                            if viewModel.showConfirmPassword {
                                TextField("Confirm Password", text: $viewModel.confirmPassword)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.primaryColor)
                                    .focused($focusedField, equals: .confirmPassword)
                            } else {
                                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Theme.primaryColor)
                                    .focused($focusedField, equals: .confirmPassword)
                            }
                            
                            Button(action: {
                                viewModel.showConfirmPassword.toggle()
                            }) {
                                Image(systemName: viewModel.showConfirmPassword ? "eye.slash" : "eye")
                                    .foregroundColor(Theme.primaryColor)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 54)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, Theme.Spacing.sm)
                    
                    // Forgot Password Link (as per Figma design)
//                    HStack {
//                        Spacer()
//                        Button(action: {
//                            // Navigate to password reset or show alert
//                        }) {
//                            Text("Forgot Password?")
//                                .font(.system(size: 13, weight: .semibold))
//                                .foregroundColor(Theme.primaryColor)
//                        }
//                        .padding(.trailing, 28)
//                    }
//                    .padding(.bottom, Theme.Spacing.lg)
                    
                    Spacer().frame(height: 20)
                    // Sign Up Button
                    Button(action: {
                        viewModel.signUp()
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 43)
                            .background(Theme.primaryColor)
                            .cornerRadius(50)
                    }
                    .disabled(!viewModel.canSignUp || viewModel.isLoading)
                    .opacity((viewModel.canSignUp && !viewModel.isLoading) ? 1.0 : 0.6)
                    .padding(.horizontal, 28)
                    .padding(.bottom, Theme.Spacing.md)
                    
                    // Sign In Link
                    HStack {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            router.navigate(to: .login)
                        }) {
                            Text("Sign In")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Theme.primaryColor)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                }
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Sign Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.setRouter(router)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AppRouter())
}
