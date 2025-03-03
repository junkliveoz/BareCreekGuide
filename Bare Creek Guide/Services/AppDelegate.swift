//
//  AppDelegate.swift
//  Bare Creek Guide
//
//  Created by Adam on 3/3/2025.
//

import SwiftUI
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("App did finish launching")
        
        // Configure notification handling
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification authorization
        requestNotificationAuthorization()
        
        // Register for background fetch - critical for background updates
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    // Request permission for notifications
    private func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification authorization granted")
                
                // Register for remote notifications
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else if let error = error {
                print("Failed to request notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Allow showing notifications when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Store device token for use with your notification service
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Handle background fetch - this is the key method for background weather updates
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Background fetch started")
        
        Task {
            do {
                let weatherService = WeatherService.shared
                let weatherData = try await weatherService.fetchWeatherDataAsync()
                
                // Process the current weather data
                let viewModel = ParkStatusViewModel(weatherService: weatherService)
                
                // Update viewModel with latest data
                viewModel.updateWeatherData(weatherData)
                
                // Calculate two-day rain total
                viewModel.calculateTwoDayRainTotal(weatherData)
                
                // Process notifications based on weather data
                NotificationManager.shared.processWeatherUpdate(
                    currentWeather: weatherData.first,
                    parkStatus: viewModel.parkStatus,
                    twoDayRainTotal: viewModel.twoDayRainTotal,
                    isParkOpen: viewModel.isParkOpenBasedOnTime
                )
                
                print("Background fetch completed successfully")
                completionHandler(.newData)
            } catch {
                print("Background fetch failed: \(error.localizedDescription)")
                completionHandler(.failed)
            }
        }
    }
    
    // App state change handlers
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App did become active")
        // Refresh weather data when app becomes active
        Task {
            await ParkStatusViewModel.shared.fetchLatestWeatherAsync()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        // Request background fetch when app enters background
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    }
}
