//
//  Bare_Creek_Guide.swift
//  Bare Creek Guide
//
//  Created by Adam on 22/2/2025.
//

import SwiftUI
import WatchConnectivity

@main
struct Bare_Creek_GuideApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    var body: some Scene {
        WindowGroup {
            SplashScreen()
        }
    }
}

