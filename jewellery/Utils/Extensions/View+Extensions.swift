import SwiftUI

extension View {
    /// Custom animated search bar – appears only when magnifying glass is tapped, pushes content down
    func animatedSearchBar(
        text: Binding<String>,
        isPresented: Binding<Bool>,
        placeholder: String
    ) -> some View {
        self.safeAreaInset(edge: .top, spacing: 0) {
            if isPresented.wrappedValue {
                AnimatedSearchBarView(
                    text: text,
                    isPresented: isPresented,
                    placeholder: placeholder
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeOut(duration: 0.25), value: isPresented.wrappedValue)
    }
}

// MARK: - Animated Search Bar
private struct AnimatedSearchBarView: View {
    @Binding var text: String
    @Binding var isPresented: Bool
    let placeholder: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .submitLabel(.search)
            Button {
                withAnimation(.easeOut(duration: 0.25)) {
                    isPresented = false
                }
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 146/255, green: 111/255, blue: 111/255))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        .onAppear {
            isFocused = true
        }
        .onDisappear {
            isFocused = false
        }
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

}
