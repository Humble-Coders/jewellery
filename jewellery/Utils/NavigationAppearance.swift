import SwiftUI
import UIKit

enum NavigationAppearance {
    static func configure(
        backgroundColor: UIColor = .white,
        foregroundColor: UIColor = .black,
        tintColor: UIColor? = nil
    ) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [
            .foregroundColor: foregroundColor,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: foregroundColor
        ]

        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: tintColor ?? foregroundColor]
        buttonAppearance.highlighted.titleTextAttributes = [.foregroundColor: (tintColor ?? foregroundColor).withAlphaComponent(0.7)]
        appearance.buttonAppearance = buttonAppearance

        let doneAppearance = UIBarButtonItemAppearance()
        doneAppearance.normal.titleTextAttributes = [.foregroundColor: tintColor ?? foregroundColor]
        appearance.doneButtonAppearance = doneAppearance

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = tintColor ?? foregroundColor
    }

    static func applyStandard() {
        configure(
            backgroundColor: .white,
            foregroundColor: .black,
            tintColor: UIColor(red: 146/255.0, green: 111/255.0, blue: 111/255.0, alpha: 1.0)
        )
    }

}
