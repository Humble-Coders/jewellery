import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isOutlined: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(isOutlined ? Theme.primaryColor : .white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(isOutlined ? Color.clear : Theme.primaryColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                        .stroke(Theme.primaryColor, lineWidth: isOutlined ? 2 : 0)
                )
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}
