import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        GeometryReader { geometry in
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Image("welcome")
                    .resizable()
                    .frame(height: geometry.size.height * 0.55)
                    .ignoresSafeArea(edges: .top)
                
                VStack(spacing: Theme.Spacing.xl) {
                    Spacer().frame(height: 50)
                    
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
                    
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: { router.navigate(to: .login) }) {
                            Text("Login")
                                .font(Theme.Typography.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 59)
                                .background(Theme.primaryColor)
                                .cornerRadius(50)
                        }
                        .padding(.horizontal, 28)
                        
                        Button(action: { router.navigate(to: .register) }) {
                            Text("Sign up")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.primaryColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 59)
                                .background(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                        .stroke(Theme.primaryColor, lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.bottom, Theme.Spacing.xl)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                
                Image("crown")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundColor(Theme.goldColor)
                    .offset(y: 70)
            }
        }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AppRouter())
}
