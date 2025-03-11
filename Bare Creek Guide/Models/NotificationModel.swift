//
//  NotificationModel.swift
//  Bare Creek Guide
//
//  Created by Adam on 5/3/2025.
//  Updated to fix badge count issues on 11/3/2025.
//

import SwiftUI
import UserNotifications

/// Represents different types of notifications in the app
enum NotificationType: String, Codable, Equatable {
    case perfectConditions
    case rain
    case tooWet
    case parkOpenClosed
    case favoriteTrails
    case generalUpdate
    
    /// Icon associated with each notification type
    var icon: String {
        switch self {
        case .perfectConditions:
            return "checkmark.circle.fill"
        case .rain:
            return "cloud.rain.fill"
        case .tooWet:
            return "exclamationmark.triangle.fill"
        case .parkOpenClosed:
            return "clock.fill"
        case .favoriteTrails:
            return "heart.fill"
        case .generalUpdate:
            return "bell.fill"
        }
    }
    
    /// Color associated with each notification type
    var color: Color {
        switch self {
        case .perfectConditions:
            return .green
        case .rain:
            return .blue
        case .tooWet:
            return .orange
        case .parkOpenClosed:
            return .purple
        case .favoriteTrails:
            return .red
        case .generalUpdate:
            return .gray
        }
    }
}

/// Represents an individual notification in the app
struct AppNotification: Identifiable, Codable, Equatable {
    let id: UUID
    let type: NotificationType
    let title: String
    let body: String
    let timestamp: Date
    var isRead: Bool
    var deepLink: String?
    
    // Add Equatable conformance
    static func == (lhs: AppNotification, rhs: AppNotification) -> Bool {
        return lhs.id == rhs.id &&
               lhs.type == rhs.type &&
               lhs.title == rhs.title &&
               lhs.body == rhs.body &&
               lhs.timestamp == rhs.timestamp &&
               lhs.isRead == rhs.isRead
    }
}

/// Manages the lifecycle and persistence of notifications
class NotificationsManager: ObservableObject {
    // Singleton instance
    static let shared = NotificationsManager()
    
    // Published property to trigger UI updates
    @Published var notifications: [AppNotification] = []
    
    // Maximum number of notifications to store
    private let maxNotifications = 100
    
    // UserDefaults key for storing notifications
    private let notificationsKey = "appNotifications"
    
    // Private initializer for singleton
    private init() {
        loadNotifications()
    }
    
    /// Add a new notification
    /// - Parameter notification: Notification to add
    func addNotification(_ notification: AppNotification) {
        // Insert at the beginning of the array
        notifications.insert(notification, at: 0)
        
        // Trim to max notifications if needed
        if notifications.count > maxNotifications {
            notifications = Array(notifications.prefix(maxNotifications))
        }
        
        // Save to persistent storage
        saveNotifications()
        
        // Update app badge
        updateAppBadge()
    }
    
    /// Mark a specific notification as read
    /// - Parameter notification: Notification to mark as read
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            saveNotifications()
            updateAppBadge()
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        notifications = notifications.map {
            var notification = $0
            notification.isRead = true
            return notification
        }
        saveNotifications()
        updateAppBadge()
    }
    
    /// Remove a specific notification
    /// - Parameter notification: Notification to remove
    func removeNotification(_ notification: AppNotification) {
        notifications.removeAll { $0.id == notification.id }
        saveNotifications()
        updateAppBadge()
    }
    
    /// Clear all notifications
    func clearAllNotifications() {
        notifications.removeAll()
        saveNotifications()
        updateAppBadge()
    }
    
    /// Number of unread notifications
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    /// Update the app badge count
    private func updateAppBadge() {
        let count = unreadCount
        
        UNUserNotificationCenter.current().setBadgeCount(count) { error in
            if let error = error {
                print("Failed to update badge count: \(error.localizedDescription)")
            } else {
                print("Updated badge count to \(count)")
            }
        }
    }
    
    /// Load notifications from UserDefaults
    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: notificationsKey),
              let savedNotifications = try? JSONDecoder().decode([AppNotification].self, from: data) else {
            return
        }
        
        // Sort notifications with most recent first
        notifications = savedNotifications.sorted { $0.timestamp > $1.timestamp }
        
        // Update badge count after loading
        updateAppBadge()
    }
    
    /// Save notifications to UserDefaults
    private func saveNotifications() {
        guard let encodedData = try? JSONEncoder().encode(notifications) else {
            return
        }
        
        UserDefaults.standard.set(encodedData, forKey: notificationsKey)
    }
    
    /// Clear old notifications (older than specified days)
    /// - Parameter days: Number of days to keep notifications
    func clearOldNotifications(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        notifications = notifications.filter { $0.timestamp > cutoffDate }
        saveNotifications()
        updateAppBadge()
    }
}
