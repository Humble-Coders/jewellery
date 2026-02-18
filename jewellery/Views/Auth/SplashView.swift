import SwiftUI
import FirebaseAuth

struct SplashView: View {
    @EnvironmentObject var router: AppRouter
    @State private var logoScale: CGFloat = 0.3
    @State private var logoRotation: Double = -20
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Gradient background
            Theme.splashGradient
                .ignoresSafeArea()
            
            VStack(spacing: Theme.Spacing.lg) {
                Spacer()
                
                // Animated Crown Logo
                ZStack {
                    Image("crown")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .scaleEffect(logoScale)
                        .rotationEffect(.degrees(logoRotation))
                        .opacity(logoOpacity)
                        .overlay(
                            // Shimmer effect
                            LinearGradient(
                                colors: [Color.clear, Color.white.opacity(0.5), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 200)
                            .offset(x: shimmerOffset)
                            .blur(radius: 10)
                        )
                }
                
                // Brand Typography
                VStack(spacing: Theme.Spacing.sm) {
                    // GAGAN
                    Text("GAGAN")
                        .font(Theme.Typography.brandSerif)
                        .foregroundColor(.primary)
                        .tracking(4)
                        .opacity(textOpacity)
                    
                    // JEWELLERS
                    Text("JEWELLERS")
                        .font(Theme.Typography.brandSans)
                        .foregroundColor(Theme.goldColor)
                        .tracking(6)
                        .opacity(textOpacity)
                    
                    // Tagline
                    Text("Crafting Timeless Elegance")
                        .font(Theme.Typography.caption)
                        .foregroundColor(.secondary)
                        .opacity(textOpacity)
                }
                
                Spacer()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Staggered animation sequence
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            logoOpacity = 1.0
            logoScale = 1.0
            logoRotation = 0
        }
        
        // Shimmer animation
        withAnimation(.linear(duration: 1.5).repeatCount(2, autoreverses: false)) {
            shimmerOffset = 200
        }
        
        Task {
            // Text fade in after logo
            try? await Task.sleep(nanoseconds: 500_000_000)
            withAnimation(.easeIn(duration: 0.8)) {
                textOpacity = 1.0
            }
            
            // Wait remaining time, then check auth and navigate
            let remaining = Constants.Animation.splashDuration - 0.5
            try? await Task.sleep(nanoseconds: UInt64(max(remaining, 0) * 1_000_000_000))
            await checkAuthAndNavigate()
        }
    }
    
    @MainActor
    private func checkAuthAndNavigate() async {
        if FirebaseService.shared.auth.currentUser != nil {
            // User is persisted locally -- go straight to home.
            // Firebase refreshes the token automatically when network returns.
            router.navigate(to: .home, clearStack: true)
        } else {
            router.navigate(to: .welcome, clearStack: true)
        }
    }
}

#Preview {
    SplashView()
        .environmentObject(AppRouter())
}
