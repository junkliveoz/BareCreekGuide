//
//  Bare_Creek_WatchApp.swift
//  Bare Creek Watch Watch App
//
//  Created by Adam on 7/4/2025.
//  Updated to use renamed WatchContentView
//

import SwiftUI

@main
struct BareCreekWatchApp: App {
    // Use a StateObject to create and maintain the view model
    @StateObject private var watchViewModel = WatchViewModel()
    
    var body: some Scene {
        WindowGroup {
            WatchContentView() // Changed from ContentView to WatchContentView
                .environmentObject(watchViewModel)
        }
        
        // Add notification support
        WKNotificationScene(controller: NotificationController.self, category: "parkStatus")
    }
}
