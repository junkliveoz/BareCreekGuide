//
//  ContentView.swift
//  Bare Creek Guide
//
//  Update for notification indicator on 12/3/2025
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ParkStatusViewModel()
    @State private var selectedTab = 0
    
    // Notifications management
    @StateObject private var notificationsManager = NotificationsManager.shared
    @State private var showNotifications = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Park Status Tab
            NavigationView {
                ParkStatusView(viewModel: viewModel)
                    .navigationBarItems(trailing: notificationsButton)
            }
            .tabItem {
                // We can't easily modify the tab bar item itself, but we'll use a standard icon
                // The notification indicator will be in the navigation bar
                Image(systemName: "cloud.sun.fill")
                Text("Conditions")
            }
            .tag(0)
            
            // Trails Tab
            NavigationView {
                TrailsView(parkStatusViewModel: viewModel)
            }
            .tabItem {
                Image(systemName: "mountain.2.fill")
                Text("Trails")
            }
            .tag(1)
            
            // Info Tab
            NavigationView {
                InfoView()
            }
            .tabItem {
                Image(systemName: "info.circle.fill")
                Text("Info")
            }
            .tag(2)
            
            // Settings Tab
            NavigationView {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(3)
        }
        .accentColor(Color("AccentColor"))
        .sheet(isPresented: $showNotifications) {
            NotificationsView()
        }
        .overlay(
            // Add an indicator dot when there are unread notifications and user is not on the Conditions tab
            notificationsManager.unreadCount > 0 && selectedTab != 0 ?
                AnyView(NotificationIndicator(count: notificationsManager.unreadCount, onTap: {
                    selectedTab = 0  // Switch to Conditions tab when tapped
                }))
                : AnyView(EmptyView())
        )
    }
    
    // Notifications button with unread count
    private var notificationsButton: some View {
        Button(action: {
            showNotifications = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "bell.fill")
                    .imageScale(.medium)
                
                if notificationsManager.unreadCount > 0 {
                    Text("\(notificationsManager.unreadCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .foregroundColor(Color("AccentColor"))
        }
    }
}

// A floating notification indicator that appears when there are unread notifications
struct NotificationIndicator: View {
    let count: Int
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Image(systemName: "bell.fill")
                        Text("\(count) new")
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(Color.red)
                    )
                    .foregroundColor(.white)
                    .shadow(radius: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 80) // Position above tab bar
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
