//
//  ContentView.swift
//  jewellery
//
//  Created by Sharnya  Goel on 17/01/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Group {
            if router.showMainApp {
                MainTabView()
            } else {
                NavigationStack(path: $router.navigationPath) {
                    SplashView()
                        .navigationDestination(for: AppRoute.self) { route in
                            authRouteView(for: route)
                        }
                }
            }
        }
    }
    
    @ViewBuilder
    private func authRouteView(for route: AppRoute) -> some View {
        switch route {
        case .welcome:
            WelcomeView()
        case .login:
            LoginView()
        case .register:
            RegisterView()
        case .home:
            EmptyView()
        default:
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppRouter())
}
