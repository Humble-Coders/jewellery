import SwiftUI

struct Toast: ViewModifier {
    @Binding var isPresented: Bool
    let message: String
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                VStack {
                    Spacer()
                    Text(message)
                        .font(Theme.Typography.body)
                        .foregroundColor(.white)
                        .padding(Theme.Spacing.md)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(Theme.CornerRadius.medium)
                        .padding(Theme.Spacing.lg)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: isPresented)
            }
        }
        .onChange(of: isPresented) { newValue in
            if newValue {
                Task {
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        }
    }
}

extension View {
    func toast(isPresented: Binding<Bool>, message: String, duration: TimeInterval = 2.0) -> some View {
        modifier(Toast(isPresented: isPresented, message: message, duration: duration))
    }
}
