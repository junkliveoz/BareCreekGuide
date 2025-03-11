//
//  ContentView.swift
//  Bare Creek Guide
//
//  Update for MVVM architecture on 11/3/2025
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
                Image(systemName: "cloud.sun.fill")
                Text("Conditions")
            }
            .tag(0)
            
            // Trails Tab - Updated to use the new MVVM Trail views
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
}
