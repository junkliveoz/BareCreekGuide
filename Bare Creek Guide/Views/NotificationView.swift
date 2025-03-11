//
//  NotificationView.swift
//  Bare Creek Guide
//
//  Created by Adam on 5/3/2025.
//

import SwiftUI

struct NotificationsView: View {
    @StateObject private var notificationsManager = NotificationsManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if notificationsManager.notifications.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("No Notifications")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text("You're all caught up!")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Notifications list
                    List {
                        ForEach(notificationsManager.notifications) { notification in
                            NotificationRowView(notification: notification)
                                .listRowSeparator(.hidden)
                                .listRowBackground(notification.isRead ? Color(.systemBackground) : Color(.systemGray6))
                                .onTapGesture {
                                    notificationsManager.markAsRead(notification)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .animation(.default, value: notificationsManager.notifications)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing:
                    Group {
                        if !notificationsManager.notifications.isEmpty {
                            Button("Mark All Read") {
                                notificationsManager.markAllAsRead()
                            }
                        }
                    }
            )
        }
    }
}

struct NotificationRowView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(spacing: 12) {
            // Notification Type Icon
            Image(systemName: notification.type.icon)
                .foregroundColor(notification.type.color)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(notification.isRead ? .regular : .bold)
                
                // Body
                Text(notification.body)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Timestamp
                Text(formatTimestamp(notification.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Unread indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(notification.isRead ? Color.clear : Color(.systemGray6).opacity(0.5))
        )
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Preview for testing
struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        // Populate some sample notifications for preview
        let sampleNotifications = [
            AppNotification(
                id: UUID(),
                type: .perfectConditions,
                title: "Perfect Conditions",
                body: "Wind gusts are below 16km/h at Bare Creek",
                timestamp: Date(),
                isRead: false
            ),
            AppNotification(
                id: UUID(),
                type: .rain,
                title: "Rain Detected",
                body: "Rain has been detected at the weather station",
                timestamp: Date(),
                isRead: true
            ),
            AppNotification(
                id: UUID(),
                type: .favoriteTrails,
                title: "Favorite Trail Open",
                body: "Livewire trail is now open!",
                timestamp: Date(),
                isRead: false
            )
        ]
        
        // Set sample notifications for preview
        NotificationsManager.shared.notifications = sampleNotifications
        
        return NotificationsView()
    }
}
