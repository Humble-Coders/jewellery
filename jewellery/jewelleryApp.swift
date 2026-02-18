//
//  jewelleryApp.swift
//  jewellery
//
//  Created by Sharnya  Goel on 17/01/26.
//

import SwiftUI
import FirebaseCore

@main
struct jewelleryApp: App {
    @StateObject private var router = AppRouter()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    init() {
        FirebaseApp.configure()
        FirebaseService.shared.configure()
        NavigationAppearance.applyStandard()
        
        // Configure SDWebImage for image caching
        ImageCacheConfiguration.configure()
        
        // Legacy URLCache for other network requests
        configureURLCache()
    }
    
    private func configureURLCache() {
        let memoryCapacity = 50 * 1024 * 1024  // 50 MB
        let diskCapacity = 100 * 1024 * 1024   // 100 MB
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity)
        URLCache.shared = cache
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(router)
                .environmentObject(networkMonitor)
                .preferredColorScheme(.light)
        }
    }
}
