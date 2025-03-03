import SwiftUI
import UserNotifications

class NotificationSettings: ObservableObject {
    static let shared = NotificationSettings()
    
    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
            updateNotificationSettings()
            
            // If notifications are disabled, turn off all specific notifications
            if !notificationsEnabled {
                notifyPerfectConditions = false
                notifyRain = false
                notifyTooWet = false
                notifyOpenClosed = false
                notifyFavoriteTrails = false
            }
        }
    }
    
    @Published var notifyPerfectConditions: Bool {
        didSet {
            UserDefaults.standard.set(notifyPerfectConditions, forKey: "notifyPerfectConditions")
            // If any notification type is enabled, ensure main notifications are enabled
            updateMainNotificationsStatus()
        }
    }
    
    @Published var notifyRain: Bool {
        didSet {
            UserDefaults.standard.set(notifyRain, forKey: "notifyRain")
            // If any notification type is enabled, ensure main notifications are enabled
            updateMainNotificationsStatus()
        }
    }
    
    @Published var notifyTooWet: Bool {
        didSet {
            UserDefaults.standard.set(notifyTooWet, forKey: "notifyTooWet")
            // If any notification type is enabled, ensure main notifications are enabled
            updateMainNotificationsStatus()
        }
    }
    
    @Published var notifyOpenClosed: Bool {
        didSet {
            UserDefaults.standard.set(notifyOpenClosed, forKey: "notifyOpenClosed")
            // If any notification type is enabled, ensure main notifications are enabled
            updateMainNotificationsStatus()
        }
    }
    
    @Published var notifyFavoriteTrails: Bool {
        didSet {
            UserDefaults.standard.set(notifyFavoriteTrails, forKey: "notifyFavoriteTrails")
            // If any notification type is enabled, ensure main notifications are enabled
            updateMainNotificationsStatus()
        }
    }
    
    @Published var notificationsAuthorized = false
    
    private init() {
        // Load saved preferences
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.notifyPerfectConditions = UserDefaults.standard.bool(forKey: "notifyPerfectConditions")
        self.notifyRain = UserDefaults.standard.bool(forKey: "notifyRain")
        self.notifyTooWet = UserDefaults.standard.bool(forKey: "notifyTooWet")
        self.notifyOpenClosed = UserDefaults.standard.bool(forKey: "notifyOpenClosed")
        self.notifyFavoriteTrails = UserDefaults.standard.bool(forKey: "notifyFavoriteTrails")
        
        // Check notification authorization status
        checkNotificationAuthorization()
    }
    
    /// Update main notifications status based on specific notification types
    private func updateMainNotificationsStatus() {
        if notifyPerfectConditions || notifyRain || notifyTooWet || notifyOpenClosed || notifyFavoriteTrails {
            notificationsEnabled = true
        }
    }
    
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationsAuthorized = settings.authorizationStatus == .authorized
                
                // If not authorized, ensure notificationsEnabled is false
                if settings.authorizationStatus != .authorized {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            DispatchQueue.main.async {
                self.notificationsAuthorized = success
                
                // If authorization was successful, enable notifications
                if success {
                    self.notificationsEnabled = true
                    self.updateNotificationSettings()
                }
            }
        }
    }
    
    private func updateNotificationSettings() {
        // This would connect to your notification service/backend
        // For now, we'll just print the settings
        print("Updated notification settings: Enabled: \(notificationsEnabled), Perfect: \(notifyPerfectConditions), Rain: \(notifyRain), Too Wet: \(notifyTooWet), Open/Closed: \(notifyOpenClosed), Favorite Trails: \(notifyFavoriteTrails)")
    }
}

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var notificationSettings = NotificationSettings.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enable/Disable Notifications
                VStack {
                    Text("NOTIFICATION PREFERENCES")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                    
                    Button(action: {
                        if notificationSettings.notificationsAuthorized {
                            // Toggle notifications on/off
                            notificationSettings.notificationsEnabled.toggle()
                        } else {
                            // Request permission
                            notificationSettings.requestNotificationAuthorization()
                        }
                    }) {
                        HStack {
                            Image(systemName: notificationSettings.notificationsEnabled ? "bell.fill" : "bell.slash")
                                .foregroundColor(notificationSettings.notificationsEnabled ? Color("AccentColor") : .red)
                                .font(.system(size: 24))
                                .frame(width: 40)
                            
                            Text(notificationSettings.notificationsEnabled ? "Turn Off Notifications" : "Enable Notifications")
                                .font(.title3)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                
                // Notification Options
                VStack {
                    Text("ABOUT NOTIFICATIONS")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    
                    // Notification type toggles
                    VStack(spacing: 0) {
                        // Perfect Conditions
                        NotificationToggleRow(
                            icon: "checkmark.circle.fill",
                            iconColor: .green,
                            title: "Perfect Conditions",
                            description: "Notify when wind gusts are 15kmh or below.",
                            isOn: $notificationSettings.notifyPerfectConditions,
                            isEnabled: notificationSettings.notificationsEnabled
                        )
                        
                        // Rain Detection
                        NotificationToggleRow(
                            icon: "cloud.rain.fill",
                            iconColor: .blue,
                            title: "Rain Detection",
                            description: "Notify when rain is detected at the weather station.",
                            isOn: $notificationSettings.notifyRain,
                            isEnabled: notificationSettings.notificationsEnabled
                        )
                        
                        // Too Wet
                        NotificationToggleRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: .orange,
                            title: "Too Wet",
                            description: "Notify when rain exceeds 7mm over 2 days.",
                            isOn: $notificationSettings.notifyTooWet,
                            isEnabled: notificationSettings.notificationsEnabled
                        )
                        
                        // Park Open/Closed
                        NotificationToggleRow(
                            icon: "clock.fill",
                            iconColor: .purple,
                            title: "Park Open/Closed",
                            description: "Notify of park opening hours (6am to 5/7pm) and condition-based closures.",
                            isOn: $notificationSettings.notifyOpenClosed,
                            isEnabled: notificationSettings.notificationsEnabled
                        )
                        
                        // Favorite Trails
                        NotificationToggleRow(
                            icon: "heart.fill",
                            iconColor: .red,
                            title: "Favorite Trails Updates",
                            description: "Notify when your favorite trails open or close, including trails that require a safety officer.",
                            isOn: $notificationSettings.notifyFavoriteTrails,
                            isEnabled: notificationSettings.notificationsEnabled
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                Text("Notifications are sent based on weather data from the Bureau of Meteorology.")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
            .navigationTitle("Settings")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

// Custom row for notification toggles
struct NotificationToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    @Binding var isOn: Bool
    let isEnabled: Bool
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .font(.system(size: 24))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(!isEnabled)
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
