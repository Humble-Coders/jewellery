import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var router: AppRouter
    @FocusState private var focusedField: Field?
    
    enum Field {
        case emailOrPhone
        case password
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
                        .frame(height: 20)
                    
                    // Crown Logo
                    Image("crown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(Theme.goldColor)
                        .padding(.bottom, Theme.Spacing.md)
                    
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
                    .padding(.bottom, Theme.Spacing.xl)
                    
                    // Welcome Back Text
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("Welcome Back")
                            .font(.system(size: 36, weight: .semibold, design: .default))
                            .foregroundColor(Theme.primaryColor)
                        
                        Text("Login to your account")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "#d9d9d9"))
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                    
                    // Input Fields
                    VStack(spacing: Theme.Spacing.md) {
                        // Email/Phone Field
                        HStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "person")
                                .foregroundColor(Theme.primaryColor)
                                .frame(width: 20, height: 20)
                            
                            TextField("Email id / Phone Number", text: $viewModel.emailOrPhone)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Theme.primaryColor)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .focused($focusedField, equals: .emailOrPhone)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .frame(height: 59)
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
                        .frame(height: 59)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(Theme.primaryColor, lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, Theme.Spacing.sm)
                    
                    // Forgot Password Link
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.sendPasswordReset()
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Theme.primaryColor)
                        }
                        .padding(.trailing, 28)
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                    
                    // Login Button
                    Button(action: {
                        viewModel.signIn()
                    }) {
                        Text("Login")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 41)
                            .background(Theme.primaryColor)
                            .cornerRadius(50)
                    }
                    .disabled(!viewModel.canLogin || viewModel.isLoading)
                    .opacity((viewModel.canLogin && !viewModel.isLoading) ? 1.0 : 0.6)
                    .padding(.horizontal, 28)
                    .padding(.bottom, Theme.Spacing.lg)
                    
                    // Google Sign-In Button (Optional - can be enabled when Google Sign-In SDK is added)
                    // Button(action: {
                    //     viewModel.signInWithGoogle()
                    // }) {
                    //     HStack(spacing: Theme.Spacing.sm) {
                    //         Image(systemName: "globe")
                    //             .foregroundColor(Theme.primaryColor)
                    //         
                    //         Text("Continue with Google")
                    //             .font(.custom("Poppins", size: 16))
                    //             .fontWeight(.semibold)
                    //             .foregroundColor(Theme.primaryColor)
                    //     }
                    //     .frame(maxWidth: .infinity)
                    //     .frame(height: 50)
                    //     .background(Color.white)
                    //     .overlay(
                    //         RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    //             .stroke(Theme.primaryColor, lineWidth: 1)
                    //     )
                    // }
                    // .disabled(viewModel.isLoading)
                    // .opacity(viewModel.isLoading ? 0.6 : 1.0)
                    // .padding(.horizontal, Theme.Spacing.lg)
                    // .padding(.bottom, Theme.Spacing.xl)
                }
                }
            }
            
            // Loading Overlay
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationTitle("Login")
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
        .alert("Password Reset", isPresented: $viewModel.passwordResetSent) {
            Button("OK", role: .cancel) {
                viewModel.passwordResetSent = false
            }
        } message: {
            Text(viewModel.passwordResetMessage)
        }
        .onTapGesture {
            focusedField = nil
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppRouter())
}
