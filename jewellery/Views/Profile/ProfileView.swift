import SwiftUI
import FirebaseFirestore

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var router: AppRouter
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var editedPhone = ""
    @State private var editedDateOfBirth: Date = Date()
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            if viewModel.isLoading && viewModel.user == nil {
                LoadingView()
            } else if viewModel.user == nil {
                // Show login required screen
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer()
                    
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .font(.system(size: 80))
                        .foregroundColor(Color(hex: "#C9A87C"))
                    
                    Text("Login Required")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Please sign in to view your profile")
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#808080"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                    
                    PrimaryButton(
                        title: "Go to Login",
                        action: {
                            router.navigate(to: .welcome, clearStack: true)
                        }
                    )
                    .padding(.horizontal, Theme.Spacing.xl)
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Profile Picture and Welcome Text
                        VStack(spacing: Theme.Spacing.md) {
                            // Profile Picture
                            if let profileUrl = viewModel.user?.profilePictureUrl, !profileUrl.isEmpty {
                                AsyncImage(url: URL(string: profileUrl)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Circle()
                                        .fill(Color(hex: "#E8DED5"))
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 50))
                                                .foregroundColor(Color(hex: "#6B5A52"))
                                        )
                                }
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#C9A87C"), lineWidth: 3)
                                )
                            } else {
                                // Default avatar
                                Circle()
                                    .fill(Color(hex: "#E8DED5"))
                                    .frame(width: 140, height: 140)
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(Color(hex: "#6B5A52"))
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color(hex: "#C9A87C"), lineWidth: 3)
                                    )
                            }
                            
                            // Welcome Text
                            Text("Welcome, \(viewModel.user?.displayName ?? "User")")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                            
                            // Email
                            Text(viewModel.user?.displayEmail ?? "")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(hex: "#808080"))
                        }
                        .padding(.top, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xl)
                        
                        // Personal Information Card
                        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                            // Section Header
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#6B5A52"))
                                
                                Text("Personal Information")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .padding(.bottom, Theme.Spacing.sm)
                            
                            // Full Name
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#6B5A52"))
                                    
                                    Text("Full Name *")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                
                                if isEditing {
                                    TextField("Enter your name", text: $editedName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                } else {
                                    Text(viewModel.user?.name ?? "Not provided")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#6B5A52"))
                                    
                                    Text("Email")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(viewModel.user?.email ?? "Not provided")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                    
                                    Text("Email cannot be changed")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color(hex: "#808080"))
                                        .padding(.leading, Theme.Spacing.md)
                                }
                            }
                            
                            // Phone Number
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#6B5A52"))
                                    
                                    Text("Phone Number")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                
                                if isEditing {
                                    TextField("Enter your phone number", text: $editedPhone)
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .keyboardType(.phonePad)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                } else {
                                    Text(viewModel.user?.displayPhone ?? "Not provided")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                }
                            }
                            
                            // Date of Birth
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                HStack(spacing: Theme.Spacing.sm) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14))
                                        .foregroundColor(Color(hex: "#6B5A52"))
                                    
                                    Text("Date of Birth")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.black)
                                }
                                
                                if isEditing {
                                    DatePicker("", selection: $editedDateOfBirth, displayedComponents: .date)
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                } else {
                                    Text(viewModel.user?.displayDateOfBirth ?? "Not provided")
                                        .font(.system(size: 16))
                                        .foregroundColor(.black)
                                        .padding(.horizontal, Theme.Spacing.md)
                                        .frame(height: 50)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(hex: "#F5F5F5"))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.lg)
                        
                        // Account Actions Card
                        VStack(spacing: Theme.Spacing.md) {
                            // Section Header
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(Color(hex: "#6B5A52"))
                                
                                Text("Account Actions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.bottom, 0)
                            .padding(.top, -14)
                            
                            // Sign Out Button
                            Button(action: {
                                viewModel.showSignOutConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 18))
                                        .foregroundColor(.white)
                                    
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(hex: "#6B5A52"))
                                .cornerRadius(8)
                            }
                            
                            // Delete Account Button
                            Button(action: {
                                viewModel.showDeleteAccountConfirmation = true
                            }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.red)
                                    
                                    Text("Delete Account")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.red)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.red, lineWidth: 1.5)
                                )
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.xl)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, Theme.Spacing.xl)
                    }
                }
            }
        }
        .blur(radius: router.showSidebar ? 3 : 0)
        .animation(.easeInOut(duration: 0.3), value: router.showSidebar)
        .navigationTitle("My Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(red: 0.77, green: 0.62, blue: 0.62), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        router.showSidebar = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    if isEditing {
                        viewModel.updateUserProfile(
                            name: editedName,
                            phone: editedPhone,
                            dateOfBirth: editedDateOfBirth
                        )
                        isEditing = false
                    } else {
                        editedName = viewModel.user?.name ?? ""
                        editedPhone = viewModel.user?.phone ?? ""
                        if let dob = viewModel.user?.dateOfBirth {
                            editedDateOfBirth = dob.dateValue()
                        } else {
                            editedDateOfBirth = Date()
                        }
                        isEditing = true
                    }
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            router.currentRoute = .profile
            viewModel.setRouter(router)
            viewModel.fetchUserData()
        }
        .alert("Sign Out", isPresented: $viewModel.showSignOutConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $viewModel.showDeleteAccountConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                viewModel.deleteAccount()
            }
        } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppRouter())
}
