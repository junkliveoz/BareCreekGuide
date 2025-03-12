//
//  NotificationManager.swift
//  Bare Creek Guide
//
//  Created on 3/3/2025.
//  Updated on 4/3/2025.
//  Updated with fixes for notification issues on 5/3/2025.
//  Updated to fix duplicate notifications and badge count issues on 11/3/2025.
//  Throttling mechanism removed on 12/3/2025.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    // Singleton instance
    static let shared = NotificationManager()
    
    // Notification settings reference
    private var notificationSettings: NotificationSettings {
        return NotificationSettings.shared
    }
    
    // Notifications manager for in-app notifications
    private var notificationsManager = NotificationsManager.shared
    
    // State tracking variables
    private var lastParkStatus: ParkStatus?
    private var lastRainCondition: Bool?
    private var lastParkOpen: Bool?
    private var lastTrailStatusMap: [String: TrailStatus] = [:]
    
    // User defaults keys for storing state
    private let lastParkStatusKey = "lastParkStatus"
    private let lastRainConditionKey = "lastRainCondition"
    private let lastParkOpenKey = "lastParkOpen"
    private let lastTrailStatusMapKey = "lastTrailStatusMap"
    private let lastNotificationTimeKey = "lastNotificationTime"
    
    // Flag to track if we've already sent a general park status notification
    private var sentParkStatusNotification = false
    
    // Private initializer for singleton
    private init() {
        // Load last states from UserDefaults
        loadSavedStates()
        
        // Print current notification settings
        printNotificationSettings()
    }
    
    // Print current notification settings for debugging
    private func printNotificationSettings() {
        print("Notification Settings:")
        print("- Notifications Enabled: \(notificationSettings.notificationsEnabled)")
        print("- Notifications Authorized: \(notificationSettings.notificationsAuthorized)")
        print("- Notify Perfect Conditions: \(notificationSettings.notifyPerfectConditions)")
        print("- Notify Rain: \(notificationSettings.notifyRain)")
        print("- Notify Too Wet: \(notificationSettings.notifyTooWet)")
        print("- Notify Open/Closed: \(notificationSettings.notifyOpenClosed)")
        print("- Notify Favorite Trails: \(notificationSettings.notifyFavoriteTrails)")
    }
    
    // Load saved states from UserDefaults
    private func loadSavedStates() {
        // Load park status
        if let statusRawValue = UserDefaults.standard.string(forKey: lastParkStatusKey) {
            switch statusRawValue {
            case "closed": lastParkStatus = .closed
            case "perfectConditions": lastParkStatus = .perfectConditions
            case "windyConditions": lastParkStatus = .windyConditions
            case "strongWinds": lastParkStatus = .strongWinds
            case "extremeWinds": lastParkStatus = .extremeWinds
            case "wetConditions": lastParkStatus = .wetConditions
            default: break
            }
        }
        
        // Load rain condition
        lastRainCondition = UserDefaults.standard.object(forKey: lastRainConditionKey) as? Bool
        
        // Load park open status
        lastParkOpen = UserDefaults.standard.object(forKey: lastParkOpenKey) as? Bool
        
        // Load trail status map
        if let savedData = UserDefaults.standard.data(forKey: lastTrailStatusMapKey),
           let savedMap = try? JSONDecoder().decode([String: String].self, from: savedData) {
            
            var statusMap: [String: TrailStatus] = [:]
            
            for (trailID, statusRawValue) in savedMap {
                let status: TrailStatus
                switch statusRawValue {
                case "Open": status = .open
                case "Open if Safety Officer onsite": status = .openWithSafetyOfficer
                case "Caution": status = .caution
                case "Closed": status = .closed
                default: continue
                }
                
                statusMap[trailID] = status
            }
            
            lastTrailStatusMap = statusMap
        }
        
        print("Loaded saved states:")
        print("- Last Park Status: \(String(describing: lastParkStatus))")
        print("- Last Rain Condition: \(String(describing: lastRainCondition))")
        print("- Last Park Open: \(String(describing: lastParkOpen))")
        print("- Last Trail Statuses: \(lastTrailStatusMap.count) trails saved")
    }
    
    // Save current states to UserDefaults
    private func saveCurrentStates(parkStatus: ParkStatus, isRaining: Bool, isParkOpen: Bool, trailStatuses: [String: TrailStatus]) {
        // Save park status
        let statusRawValue: String
        switch parkStatus {
        case .closed: statusRawValue = "closed"
        case .perfectConditions: statusRawValue = "perfectConditions"
        case .windyConditions: statusRawValue = "windyConditions"
        case .strongWinds: statusRawValue = "strongWinds"
        case .extremeWinds: statusRawValue = "extremeWinds"
        case .wetConditions: statusRawValue = "wetConditions"
        }
        UserDefaults.standard.set(statusRawValue, forKey: lastParkStatusKey)
        
        // Save rain condition
        UserDefaults.standard.set(isRaining, forKey: lastRainConditionKey)
        
        // Save park open status
        UserDefaults.standard.set(isParkOpen, forKey: lastParkOpenKey)
        
        // Save trail status map
        var statusStringMap: [String: String] = [:]
        
        for (trailID, status) in trailStatuses {
            statusStringMap[trailID] = status.rawValue
        }
        
        if let encodedData = try? JSONEncoder().encode(statusStringMap) {
            UserDefaults.standard.set(encodedData, forKey: lastTrailStatusMapKey)
        }
        
        print("Saved current states:")
        print("- Park Status: \(parkStatus)")
        print("- Is Raining: \(isRaining)")
        print("- Is Park Open: \(isParkOpen)")
        print("- Trail Statuses: \(trailStatuses.count) trails")
    }
    
    // Process weather update and generate notifications
    func processWeatherUpdate(currentWeather: WeatherData?, parkStatus: ParkStatus, twoDayRainTotal: Double, isParkOpen: Bool) {
        print("Processing weather update: Park status: \(parkStatus), Rain total: \(twoDayRainTotal), Park open: \(isParkOpen)")
        
        // Reset the park status notification flag
        sentParkStatusNotification = false
        
        // Check if notifications are authorized and enabled
        guard notificationSettings.notificationsAuthorized && notificationSettings.notificationsEnabled else {
            print("Notifications not authorized or enabled")
            
            // Still save the current states for next comparison
            let currentTrailStatuses = getCurrentTrailStatuses(for: parkStatus)
            saveCurrentStates(
                parkStatus: parkStatus,
                isRaining: currentWeather?.rain_since_9am ?? 0 > 0,
                isParkOpen: isParkOpen,
                trailStatuses: currentTrailStatuses
            )
            return
        }
        
        // No throttling - always allow notifications
        
        var sentNotification = false
        
        // Park Status Notifications - combine perfect conditions and open/closed
        if notificationSettings.notifyPerfectConditions || notificationSettings.notifyOpenClosed {
            sentNotification = handleParkStatusNotification(parkStatus, isParkOpen) || sentNotification
        }
        
        // Rain Notification
        if notificationSettings.notifyRain {
            sentNotification = handleRainNotification(currentWeather) || sentNotification
        }
        
        // Wet Conditions Notification
        if notificationSettings.notifyTooWet {
            sentNotification = handleWetConditionsNotification(parkStatus, twoDayRainTotal) || sentNotification
        }
        
        // Favorite Trails Notification
        if notificationSettings.notifyFavoriteTrails {
            sentNotification = processFavoriteTrailsNotifications(parkStatus: parkStatus) || sentNotification
        }
        
        // Update last states
        lastParkStatus = parkStatus
        
        // Save current states for future comparison
        let currentTrailStatuses = getCurrentTrailStatuses(for: parkStatus)
        saveCurrentStates(
            parkStatus: parkStatus,
            isRaining: currentWeather?.rain_since_9am ?? 0 > 0,
            isParkOpen: isParkOpen,
            trailStatuses: currentTrailStatuses
        )
        
        print("Sent notification: \(sentNotification)")
    }
    
    // Always allow notifications to be sent (throttling removed)
    private func shouldSendNotification() -> Bool {
        // Always allow notifications to be sent
        return true
    }
    
    // Combined Park Status Notification handler to avoid duplicates
    private func handleParkStatusNotification(_ parkStatus: ParkStatus, _ isParkOpen: Bool) -> Bool {
        guard lastParkStatus != parkStatus || (lastParkOpen != nil && lastParkOpen != isParkOpen) else {
            return false
        }
        
        print("Park status changed from \(String(describing: lastParkStatus)) to \(parkStatus)")
        print("Park open status changed from \(String(describing: lastParkOpen)) to \(isParkOpen)")
        
        var notification: AppNotification?
        
        // Handle open/closed status changes
        if notificationSettings.notifyOpenClosed && lastParkOpen != nil && lastParkOpen != isParkOpen {
            notification = AppNotification(
                id: UUID(),
                type: .parkOpenClosed,
                title: isParkOpen ? "Bare Creek is Now Open" : "Bare Creek is Now Closed",
                body: isParkOpen
                    ? "The bike park is now open for riding."
                    : "The bike park is now closed. Check opening hours or weather conditions.",
                timestamp: Date(),
                isRead: false
            )
            
            lastParkOpen = isParkOpen
            sentParkStatusNotification = true
        }
        // Handle perfect conditions changes
        else if notificationSettings.notifyPerfectConditions && lastParkStatus != parkStatus {
            if parkStatus == .perfectConditions && lastParkStatus != .perfectConditions {
                notification = AppNotification(
                    id: UUID(),
                    type: .perfectConditions,
                    title: "Perfect Riding Conditions!",
                    body: "Wind gusts are below 16km/h at Bare Creek. Ideal conditions for all trails!",
                    timestamp: Date(),
                    isRead: false
                )
                sentParkStatusNotification = true
            } else if lastParkStatus == .perfectConditions && parkStatus != .perfectConditions {
                notification = AppNotification(
                    id: UUID(),
                    type: .perfectConditions,
                    title: "Conditions Have Changed",
                    body: "Bare Creek is no longer in perfect riding conditions. Check the app for details.",
                    timestamp: Date(),
                    isRead: false
                )
                sentParkStatusNotification = true
            }
        }
        
        if let notification = notification {
            print("Creating park status notification: \(notification.title)")
            notificationsManager.addNotification(notification)
            sendUserNotification(notification)
            return true
        }
        
        return false
    }
    
    // Handle Rain Notification
    private func handleRainNotification(_ currentWeather: WeatherData?) -> Bool {
        let isRaining = currentWeather?.rain_since_9am ?? 0 > 0
        
        print("Rain condition: \(isRaining), Last rain condition: \(String(describing: lastRainCondition))")
        
        guard lastRainCondition != nil && lastRainCondition != isRaining && isRaining else {
            lastRainCondition = isRaining
            return false
        }
        
        let notification = AppNotification(
            id: UUID(),
            type: .rain,
            title: "Rain Detected at Bare Creek",
            body: "Rain has been detected at the weather station. Check conditions before riding.",
            timestamp: Date(),
            isRead: false
        )
        
        print("Creating rain notification: \(notification.title)")
        notificationsManager.addNotification(notification)
        sendUserNotification(notification)
        lastRainCondition = isRaining
        
        return true
    }
    
    // Handle Wet Conditions Notification
    private func handleWetConditionsNotification(_ parkStatus: ParkStatus, _ twoDayRainTotal: Double) -> Bool {
        guard lastParkStatus != parkStatus && parkStatus == .wetConditions && lastParkStatus != .wetConditions else {
            return false
        }
        
        let notification = AppNotification(
            id: UUID(),
            type: .tooWet,
            title: "Bare Creek Too Wet to Ride",
            body: "Rain total exceeds 7mm over 2 days. The park is likely too wet for riding.",
            timestamp: Date(),
            isRead: false
        )
        
        print("Creating wet conditions notification: \(notification.title)")
        notificationsManager.addNotification(notification)
        sendUserNotification(notification)
        
        return true
    }
    
    // Process Favorite Trails Notifications
    private func processFavoriteTrailsNotifications(parkStatus: ParkStatus) -> Bool {
        let trailManager = TrailManager.shared
        let favoriteTrails = trailManager.trails.filter { $0.isFavorite }
        
        guard !favoriteTrails.isEmpty else {
            print("No favorite trails")
            return false
        }
        
        var sentNotification = false
        
        for trail in favoriteTrails {
            let trailID = trail.id.uuidString
            let currentStatus = trail.currentStatus(for: parkStatus)
            
            print("Processing favorite trail: \(trail.name), Current status: \(currentStatus.rawValue), Previous status: \(lastTrailStatusMap[trailID]?.rawValue ?? "unknown")")
            
            guard let previousStatus = lastTrailStatusMap[trailID] else {
                lastTrailStatusMap[trailID] = currentStatus
                continue
            }
            
            // Don't send individual trail notifications if the trail status hasn't changed
            // or if the change is due to a general park condition change that we've already notified about
            if previousStatus == currentStatus || (sentParkStatusNotification && parkStatus != lastParkStatus) {
                continue
            }
            
            var notification: AppNotification?
            
            // Trail opened from closed
            if previousStatus == .closed && (currentStatus == .open || currentStatus == .openWithSafetyOfficer || currentStatus == .caution) {
                let notificationBody: String
                
                if currentStatus == .openWithSafetyOfficer {
                    notificationBody = "\(trail.name) can now be ridden if a safety officer is on site."
                } else if currentStatus == .caution {
                    notificationBody = "\(trail.name) is now open with caution recommended."
                } else {
                    notificationBody = "\(trail.name) is now open and ready to ride!"
                }
                
                notification = AppNotification(
                    id: UUID(),
                    type: .favoriteTrails,
                    title: "Trail Now Open: \(trail.name)",
                    body: notificationBody,
                    timestamp: Date(),
                    isRead: false
                )
            }
            // Trail closed from open
            else if (previousStatus == .open || previousStatus == .openWithSafetyOfficer || previousStatus == .caution) && currentStatus == .closed {
                notification = AppNotification(
                    id: UUID(),
                    type: .favoriteTrails,
                    title: "Trail Now Closed: \(trail.name)",
                    body: "\(trail.name) is now closed due to current conditions.",
                    timestamp: Date(),
                    isRead: false
                )
            }
            // Safety officer requirement changed
            else if previousStatus == .open && currentStatus == .openWithSafetyOfficer {
                notification = AppNotification(
                    id: UUID(),
                    type: .favoriteTrails,
                    title: "Safety Officer Required: \(trail.name)",
                    body: "\(trail.name) now requires a safety officer to be on site.",
                    timestamp: Date(),
                    isRead: false
                )
            }
            else if previousStatus == .openWithSafetyOfficer && currentStatus == .open {
                notification = AppNotification(
                    id: UUID(),
                    type: .favoriteTrails,
                    title: "Trail Fully Open: \(trail.name)",
                    body: "\(trail.name) is now fully open and doesn't require a safety officer.",
                    timestamp: Date(),
                    isRead: false
                )
            }
            
            // Send notification if created
            if let notification = notification {
                print("Creating favorite trail notification: \(notification.title)")
                notificationsManager.addNotification(notification)
                sendUserNotification(notification)
                sentNotification = true
            }
            
            // Update trail status
            lastTrailStatusMap[trailID] = currentStatus
        }
        
        return sentNotification
    }
    
    // Get current trail statuses for a given park status
    private func getCurrentTrailStatuses(for parkStatus: ParkStatus) -> [String: TrailStatus] {
        let trailManager = TrailManager.shared
        var statusMap: [String: TrailStatus] = [:]
        
        for trail in trailManager.trails {
            let trailID = trail.id.uuidString
            let currentStatus = trail.currentStatus(for: parkStatus)
            statusMap[trailID] = currentStatus
        }
        
        return statusMap
    }
    
    // Send a system notification
    private func sendUserNotification(_ appNotification: AppNotification) {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = appNotification.title
        content.body = appNotification.body
        content.sound = .default
        
        // Set badge count to unread count
        content.badge = NSNumber(value: NotificationsManager.shared.unreadCount + 1)
        
        // Add custom data for potential deep linking or type identification
        var userInfo: [String: String] = [
            "notificationId": appNotification.id.uuidString,
            "type": appNotification.type.rawValue
        ]
        
        // Add deep link if available
        if let deepLink = appNotification.deepLink {
            userInfo["deepLink"] = deepLink
        }
        
        content.userInfo = userInfo
        
        // Create a trigger that fires immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        
        // Create notification request
        let requestIdentifier = appNotification.id.uuidString
        let request = UNNotificationRequest(
            identifier: requestIdentifier,
            content: content,
            trigger: trigger
        )
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending system notification: \(error.localizedDescription)")
            } else {
                print("System notification request added successfully: \(appNotification.title)")
            }
        }
    }
}
