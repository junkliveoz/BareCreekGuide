//
//  AppDelegate.swift
//  Bare Creek Guide
//
//  Created by Adam on 3/3/2025.
//  Fixed for background notifications on 4/3/2025
//  Updated to remove deprecated API warnings on 4/3/2025
//  Updated to fix notification issues on 5/3/2025
//  Updated to fix badge count issues on 11/3/2025
//

import SwiftUI
import UserNotifications
import BackgroundTasks
import CloudKit

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    // Background task identifiers
    private let backgroundFetchIdentifier = "com.barecreek.weatherfetch"
    private let backgroundRefreshIdentifier = "com.barecreek.weatherrefresh"
    
    // Shared managers and services
    private let weatherService = WeatherService.shared
    private let viewModel = ParkStatusViewModel.shared
    private let notificationManager = NotificationManager.shared
    private let favoritesStorageManager = FavoritesStorageManager.shared
    
    // Application launch method
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("App did finish launching")
        
        // Clear all pending notifications (run this once, then comment out)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("Cleared all existing notifications")
        
        // Configure notification handling
        configureNotifications(application)
        
        // Register background tasks
        registerBackgroundTasks()
        
        // Schedule initial background tasks
        scheduleBackgroundTasks()
        
        // Configure CloudKit
        configureCloudKit()
        
        // Check for a notification launch
        if let notification = launchOptions?[.remoteNotification] as? [String: AnyObject] {
            print("App launched from notification: \(notification)")
            // Handle notification if needed
        }
        
        return true
    }
    
    // Configure notifications - Updated for better reliability
    private func configureNotifications(_ application: UIApplication) {
        // Make sure this runs on the main thread
        DispatchQueue.main.async {
            // Set notification center delegate
            UNUserNotificationCenter.current().delegate = self
            
            // Request notification authorization
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                if granted {
                    print("Notification authorization granted")
                    
                    // Update notification settings
                    NotificationSettings.shared.notificationsAuthorized = true
                    
                    // Register for remote notifications
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                    
                    // Removed test notification call
                } else {
                    print("Notification authorization denied: \(String(describing: error))")
                    NotificationSettings.shared.notificationsAuthorized = false
                }
            }
            
            // Debug: Check current notification settings
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                print("Current notification settings:")
                print("- Authorization status: \(settings.authorizationStatus.rawValue)")
                print("- Alert setting: \(settings.alertSetting.rawValue)")
                print("- Badge setting: \(settings.badgeSetting.rawValue)")
                print("- Sound setting: \(settings.soundSetting.rawValue)")
                print("- Notification center setting: \(settings.notificationCenterSetting.rawValue)")
                print("- Lock screen setting: \(settings.lockScreenSetting.rawValue)")
            }
        }
    }
    
    // Configure CloudKit
    private func configureCloudKit() {
        // Check iCloud account status
        CKContainer.default().accountStatus { status, error in
            switch status {
            case .available:
                print("iCloud account is available")
            case .noAccount:
                print("No iCloud account signed in")
            case .restricted:
                print("iCloud account is restricted")
            case .couldNotDetermine:
                print("Could not determine iCloud account status")
            default:
                print("Unknown iCloud account status")
            }
        }
    }
    
    // Register background tasks
    private func registerBackgroundTasks() {
        // Register for background weather fetch
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchIdentifier, using: nil) { task in
            self.handleBackgroundWeatherFetch(task: task as! BGAppRefreshTask)
        }
        
        // Register for background processing
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundRefreshIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task: task as! BGProcessingTask)
        }
        
        print("Registered background tasks")
    }
    
    // Schedule background tasks
    func scheduleBackgroundTasks() {
        scheduleBackgroundWeatherFetch()
        scheduleBackgroundRefresh()
    }
    
    // Schedule background weather fetch
    private func scheduleBackgroundWeatherFetch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundFetchIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background fetch scheduled successfully")
        } catch {
            print("Could not schedule background fetch: \(error.localizedDescription)")
        }
    }
    
    // Schedule background refresh
    private func scheduleBackgroundRefresh() {
        let request = BGProcessingTaskRequest(identifier: backgroundRefreshIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60) // 60 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background refresh scheduled successfully")
        } catch {
            print("Could not schedule background refresh: \(error.localizedDescription)")
        }
    }
    
    // Handle background weather fetch - Updated with better error handling and logging
    private func handleBackgroundWeatherFetch(task: BGAppRefreshTask) {
        print("Starting background weather fetch")
        
        // Schedule next fetch before doing work
        scheduleBackgroundWeatherFetch()
        
        // Set expiration handler first
        task.expirationHandler = {
            print("Background fetch task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Fetch weather data using Task for async operation
                print("Fetching weather data...")
                let weatherData = try await self.weatherService.fetchWeatherDataAsync()
                
                // Update view model on main queue
                await MainActor.run {
                    self.viewModel.updateWeatherData(weatherData)
                    self.viewModel.calculateTwoDayRainTotal(weatherData)
                    
                    // Process notifications
                    self.notificationManager.processWeatherUpdate(
                        currentWeather: weatherData.first,
                        parkStatus: self.viewModel.parkStatus,
                        twoDayRainTotal: self.viewModel.twoDayRainTotal,
                        isParkOpen: self.viewModel.isParkOpenBasedOnTime
                    )
                }
                
                print("Background fetch completed successfully")
                task.setTaskCompleted(success: true)
            } catch {
                print("Background fetch failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // Handle background refresh - Updated with better error handling and logging
    private func handleBackgroundRefresh(task: BGProcessingTask) {
        print("Starting background refresh")
        
        // Schedule next refresh before doing work
        scheduleBackgroundRefresh()
        
        // Set expiration handler first
        task.expirationHandler = {
            print("Background refresh task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Fetch weather data using Task for async operation
                print("Fetching weather data for background refresh...")
                let weatherData = try await self.weatherService.fetchWeatherDataAsync()
                
                // Update view model on main queue
                await MainActor.run {
                    self.viewModel.updateWeatherData(weatherData)
                    self.viewModel.calculateTwoDayRainTotal(weatherData)
                    
                    // Process notifications
                    self.notificationManager.processWeatherUpdate(
                        currentWeather: weatherData.first,
                        parkStatus: self.viewModel.parkStatus,
                        twoDayRainTotal: self.viewModel.twoDayRainTotal,
                        isParkOpen: self.viewModel.isParkOpenBasedOnTime
                    )
                    
                    // Sync favorites if needed
                    self.favoritesStorageManager.syncFavorites()
                }
                
                print("Background refresh completed successfully")
                task.setTaskCompleted(success: true)
            } catch {
                print("Background refresh failed: \(error.localizedDescription)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Notification Handling
    
    // Handle foreground notifications - Updated for reliability
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification in foreground: \(notification.request.identifier)")
        
        // Show banner, sound, and badge when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge, .list])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
        
        // Create in-app notification
        createInAppNotification(from: notification)
    }
    
    // Create in-app notification from system notification
    private func createInAppNotification(from notification: UNNotification) {
        print("Creating in-app notification from system notification: \(notification.request.identifier)")
        guard let notificationId = notification.request.content.userInfo["notificationId"] as? String,
              let notificationTypeString = notification.request.content.userInfo["type"] as? String,
              let uuid = UUID(uuidString: notificationId) else {
            print("Failed to extract notification data from userInfo: \(notification.request.content.userInfo)")
            return
        }
        
        // Convert type string to NotificationType
        let notificationType: NotificationType
        switch notificationTypeString {
        case "perfectConditions":
            notificationType = .perfectConditions
        case "rain":
            notificationType = .rain
        case "tooWet":
            notificationType = .tooWet
        case "parkOpenClosed":
            notificationType = .parkOpenClosed
        case "favoriteTrails":
            notificationType = .favoriteTrails
        default:
            notificationType = .generalUpdate
        }
        
        // Create an AppNotification
        let appNotification = AppNotification(
            id: uuid,
            type: notificationType,
            title: notification.request.content.title,
            body: notification.request.content.body,
            timestamp: notification.date,
            isRead: false
        )
        
        // Add to NotificationsManager
        print("Adding notification to NotificationsManager: \(appNotification.title)")
        NotificationsManager.shared.addNotification(appNotification)
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User tapped notification: \(response.notification.request.identifier)")
        
        // Handle deep linking if available
        if let deepLink = response.notification.request.content.userInfo["deepLink"] as? String {
            print("Deep link received: \(deepLink)")
            // Implement deep linking logic here
        }
        
        // Mark notification as read
        if let notificationId = response.notification.request.content.userInfo["notificationId"] as? String,
           let uuid = UUID(uuidString: notificationId) {
            print("Marking notification \(notificationId) as read")
            let notification = NotificationsManager.shared.notifications.first { $0.id == uuid }
            if let notification = notification {
                NotificationsManager.shared.markAsRead(notification)
                
                // Update badge count after marking as read
                let unreadCount = NotificationsManager.shared.unreadCount
                UNUserNotificationCenter.current().setBadgeCount(unreadCount) { error in
                    if let error = error {
                        print("Failed to update badge count: \(error.localizedDescription)")
                    } else {
                        print("Updated badge count to \(unreadCount)")
                    }
                }
            } else {
                print("Could not find notification with ID \(notificationId) in the manager")
            }
        }
        
        completionHandler()
    }
    
    // Handle successful remote notification registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert device token to string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device token: \(tokenString)")
        
        // Save device token to UserDefaults
        UserDefaults.standard.set(tokenString, forKey: "deviceToken")
    }
    
    // Handle remote notification registration failure
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - App Lifecycle Methods
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print("App will enter foreground")
        
        // Refresh weather data
        Task {
            await viewModel.fetchLatestWeatherAsync()
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("App did become active")
        
        // Refresh weather data
        Task {
            await viewModel.fetchLatestWeatherAsync()
        }
        
        // Reset app badge based on actual unread count
        let unreadCount = NotificationsManager.shared.unreadCount
        UNUserNotificationCenter.current().setBadgeCount(unreadCount) { error in
            if let error = error {
                print("Failed to reset badge count: \(error.localizedDescription)")
            } else {
                print("Set badge count to \(unreadCount)")
            }
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("App did enter background")
        
        // Refresh background task schedule
        scheduleBackgroundTasks()
    }
}
