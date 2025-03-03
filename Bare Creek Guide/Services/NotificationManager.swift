//
//  NotificationManager.swift
//  Bare Creek Guide
//
//  Created on 3/3/2025.
//  Updated on 4/3/2025.
//

import SwiftUI
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private var notificationSettings: NotificationSettings {
        return NotificationSettings.shared
    }
    
    // State variables
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
    
    // Minimum time between notifications (5 minutes)
    private let minimumTimeBetweenNotifications: TimeInterval = 300
    
    private init() {
        // Load last states from UserDefaults
        loadSavedStates()
        
        // Print current notification settings
        printNotificationSettings()
    }
    
    private func printNotificationSettings() {
        print("Notification Settings:")
        print("- Notifications Enabled: \(notificationSettings.notificationsEnabled)")
        print("- Notifications Authorized: \(notificationSettings.notificationsAuthorized)")
        print("- Notify Perfect Conditions: \(notificationSettings.notifyPerfectConditions)")
        print("- Notify Rain: \(notificationSettings.notifyRain)")
        print("- Notify Too Wet: \(notificationSettings.notifyTooWet)")
        print("- Notify Open/Closed: \(notificationSettings.notifyOpenClosed)")
        print("- Notify Favorite Trails: \(notificationSettings.notifyFavoriteTrails)")
        
        // Check notification authorization
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("UNUserNotificationCenter settings:")
            print("- Authorization Status: \(settings.authorizationStatus.rawValue)")
            print("- Alert Setting: \(settings.alertSetting.rawValue)")
            print("- Badge Setting: \(settings.badgeSetting.rawValue)")
            print("- Sound Setting: \(settings.soundSetting.rawValue)")
            print("- Notification Center Setting: \(settings.notificationCenterSetting.rawValue)")
            print("- Lock Screen Setting: \(settings.lockScreenSetting.rawValue)")
        }
    }
    
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
    
    func processWeatherUpdate(currentWeather: WeatherData?, parkStatus: ParkStatus, twoDayRainTotal: Double, isParkOpen: Bool) {
        print("Processing weather update: Park status: \(parkStatus), Rain total: \(twoDayRainTotal), Park open: \(isParkOpen)")
        
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
        
        // Check if we should throttle notifications
        if !shouldSendNotification() {
            print("Throttling notifications - too soon since last notification")
            return
        }
        
        var sentNotification = false
        
        // Check for perfect conditions change
        if notificationSettings.notifyPerfectConditions {
            if lastParkStatus != parkStatus {
                print("Park status changed from \(String(describing: lastParkStatus)) to \(parkStatus)")
                if parkStatus == .perfectConditions && lastParkStatus != .perfectConditions {
                    sendNotification(
                        title: "Perfect Riding Conditions!",
                        body: "Wind gusts are below 15km/h at Bare Creek. Ideal conditions for all trails!"
                    )
                    sentNotification = true
                } else if lastParkStatus == .perfectConditions && parkStatus != .perfectConditions {
                    sendNotification(
                        title: "Conditions Have Changed",
                        body: "Bare Creek is no longer in perfect riding conditions. Check the app for details."
                    )
                    sentNotification = true
                }
            }
        }
        
        // Check for rain notifications
        if notificationSettings.notifyRain {
            let isRaining = currentWeather?.rain_since_9am ?? 0 > 0
            print("Rain condition: \(isRaining), Last rain condition: \(String(describing: lastRainCondition))")
            
            if lastRainCondition != nil && lastRainCondition != isRaining && isRaining {
                sendNotification(
                    title: "Rain Detected at Bare Creek",
                    body: "Rain has been detected at the weather station. Check conditions before riding."
                )
                sentNotification = true
            }
            lastRainCondition = isRaining
        }
        
        // Check for too wet notifications
        if notificationSettings.notifyTooWet {
            if lastParkStatus != parkStatus && parkStatus == .wetConditions && lastParkStatus != .wetConditions {
                sendNotification(
                    title: "Bare Creek Too Wet to Ride",
                    body: "Rain total exceeds 7mm over 2 days. The park is likely too wet for riding."
                )
                sentNotification = true
            }
        }
        
        // Check for park open/closed notifications
        if notificationSettings.notifyOpenClosed {
            print("Park open: \(isParkOpen), Last park open: \(String(describing: lastParkOpen))")
            
            if lastParkOpen != nil && lastParkOpen != isParkOpen {
                if isParkOpen {
                    sendNotification(
                        title: "Bare Creek is Now Open",
                        body: "The bike park is now open for riding."
                    )
                    sentNotification = true
                } else {
                    sendNotification(
                        title: "Bare Creek is Now Closed",
                        body: "The bike park is now closed. Check opening hours or weather conditions."
                    )
                    sentNotification = true
                }
            }
            lastParkOpen = isParkOpen
        }
        
        // Check for favorite trails notifications
        if notificationSettings.notifyFavoriteTrails {
            sentNotification = processFavoriteTrailsNotifications(parkStatus: parkStatus) || sentNotification
        }
        
        // Update last park status
        lastParkStatus = parkStatus
        
        // Save current states for future comparison
        let currentTrailStatuses = getCurrentTrailStatuses(for: parkStatus)
        saveCurrentStates(
            parkStatus: parkStatus,
            isRaining: currentWeather?.rain_since_9am ?? 0 > 0,
            isParkOpen: isParkOpen,
            trailStatuses: currentTrailStatuses
        )
        
        // Update last notification time if we sent a notification
        if sentNotification {
            updateLastNotificationTime()
        }
    }
    
    private func shouldSendNotification() -> Bool {
        // Get the last notification time
        let lastNotificationTime = UserDefaults.standard.double(forKey: lastNotificationTimeKey)
        
        // If last notification time is 0, it means we haven't sent any notifications yet
        if lastNotificationTime == 0 {
            return true
        }
        
        // Check if enough time has passed since the last notification
        let now = Date().timeIntervalSince1970
        let timeSinceLastNotification = now - lastNotificationTime
        
        print("Time since last notification: \(timeSinceLastNotification) seconds (minimum: \(minimumTimeBetweenNotifications))")
        
        return timeSinceLastNotification >= minimumTimeBetweenNotifications
    }
    
    private func updateLastNotificationTime() {
        // Save the current time as the last notification time
        let now = Date().timeIntervalSince1970
        UserDefaults.standard.set(now, forKey: lastNotificationTimeKey)
        print("Updated last notification time to: \(now)")
    }
    
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
    
    private func processFavoriteTrailsNotifications(parkStatus: ParkStatus) -> Bool {
        // Get favorite trails from TrailManager
        let trailManager = TrailManager.shared
        let favoriteTrails = trailManager.trails.filter { $0.isFavorite }
        
        // Skip if no favorites
        if favoriteTrails.isEmpty {
            print("No favorite trails")
            return false
        }
        
        var sentNotification = false
        
        // Process each favorite trail
        for trail in favoriteTrails {
            let trailID = trail.id.uuidString
            let currentStatus = trail.currentStatus(for: parkStatus)
            
            print("Processing favorite trail: \(trail.name), Current status: \(currentStatus.rawValue), Previous status: \(lastTrailStatusMap[trailID]?.rawValue ?? "unknown")")
            
            // Skip if we don't have a previous status for this trail yet
            if let previousStatus = lastTrailStatusMap[trailID] {
                // Status changed from closed to any open status (open, openWithSafetyOfficer, caution)
                if previousStatus == .closed && (currentStatus == .open || currentStatus == .openWithSafetyOfficer || currentStatus == .caution) {
                    let notificationBody: String
                    
                    if currentStatus == .openWithSafetyOfficer {
                        notificationBody = "\(trail.name) can now be ridden if a safety officer is on site."
                    } else if currentStatus == .caution {
                        notificationBody = "\(trail.name) is now open with caution recommended."
                    } else {
                        notificationBody = "\(trail.name) is now open and ready to ride!"
                    }
                    
                    sendNotification(
                        title: "Trail Now Open: \(trail.name)",
                        body: notificationBody
                    )
                    sentNotification = true
                }
                // Status changed from any open status to closed
                else if (previousStatus == .open || previousStatus == .openWithSafetyOfficer || previousStatus == .caution) && currentStatus == .closed {
                    sendNotification(
                        title: "Trail Now Closed: \(trail.name)",
                        body: "\(trail.name) is now closed due to current conditions."
                    )
                    sentNotification = true
                }
                // Status changed from open to need safety officer
                else if previousStatus == .open && currentStatus == .openWithSafetyOfficer {
                    sendNotification(
                        title: "Safety Officer Required: \(trail.name)",
                        body: "\(trail.name) now requires a safety officer to be on site."
                    )
                    sentNotification = true
                }
                // Status changed from needing safety officer to full open
                else if previousStatus == .openWithSafetyOfficer && currentStatus == .open {
                    sendNotification(
                        title: "Trail Fully Open: \(trail.name)",
                        body: "\(trail.name) is now fully open and doesn't require a safety officer."
                    )
                    sentNotification = true
                }
            }
            
            // Update the status in our map
            lastTrailStatusMap[trailID] = currentStatus
        }
        
        return sentNotification
    }
    
    private func sendNotification(title: String, body: String) {
        print("Sending notification: \"\(title)\" - \"\(body)\"")
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Create an immediate trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Create request
        let requestIdentifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
        
        // Add the request to the notification center
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification request added successfully")
            }
        }
    }
}
