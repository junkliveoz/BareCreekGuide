//
//  NotificationController.swift
//  Bare Creek Guide
//
//  Created by Adam on 7/4/2025.
//  Updated on 7/4/2025 to fix issues with color
//

import SwiftUI
import WatchKit
import UserNotifications

class NotificationController: WKUserNotificationHostingController<NotificationView> {
    var parkStatus: String = "Unknown"
    var statusColor: Color = .gray
    var windSpeed: String = "--"
    var notificationMessage: String = ""
    
    override var body: NotificationView {
        return NotificationView(
            parkStatus: parkStatus,
            statusColor: statusColor,
            windSpeed: windSpeed,
            message: notificationMessage
        )
    }
    
    override func didReceive(_ notification: UNNotification) {
        let content = notification.request.content
        
        // Extract data from notification
        if let statusString = content.userInfo["parkStatus"] as? String {
            parkStatus = statusString
        }
        
        if let colorString = content.userInfo["statusColor"] as? String {
            statusColor = colorFromString(colorString)
        }
        
        if let wind = content.userInfo["windSpeed"] as? String {
            windSpeed = wind
        }
        
        notificationMessage = content.body
    }
    
    // Convert color string to Color
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "red":
            return .red
        case "blue":
            return .blue
        default:
            return .gray
        }
    }
}

struct NotificationView: View {
    var parkStatus: String
    var statusColor: Color
    var windSpeed: String
    var message: String
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                
                Text(parkStatus)
                    .font(.headline)
                
                Spacer()
            }
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.leading)
            
            if windSpeed != "--" {
                HStack {
                    Image(systemName: "wind")
                        .imageScale(.small)
                    
                    Text("\(windSpeed) km/h")
                        .font(.subheadline)
                    
                    Spacer()
                }
                .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    NotificationView(
        parkStatus: "Perfect Conditions",
        statusColor: .green,
        windSpeed: "12.5",
        message: "Bare Creek is now in perfect conditions for riding!"
    )
}
