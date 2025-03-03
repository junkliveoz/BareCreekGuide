//
//  ContentView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 22/2/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ParkStatusViewModel()
    @State private var selectedTab = 0
    @State private var showSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Park Status Tab
            NavigationView {
                ParkStatusView(viewModel: viewModel)
                    .navigationBarItems(trailing: settingsButton)
            }
            .tabItem {
                Image(systemName: "cloud.sun.fill")
                Text("Conditions")
            }
            .tag(0)
            
            // Trails Tab
            NavigationView {
                TrailsView(viewModel: viewModel)
                    .navigationBarItems(trailing: settingsButton)
            }
            .tabItem {
                Image(systemName: "mountain.2.fill")
                Text("Trails")
            }
            .tag(1)
            
            // Info Tab
            NavigationView {
                InfoView()
                    .navigationBarItems(trailing: settingsButton)
            }
            .tabItem {
                Image(systemName: "info.circle.fill")
                Text("Info")
            }
            .tag(2)
        }
        .accentColor(Color("AccentColor"))
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            showSettings = true
        }) {
            Image(systemName: "gear")
                .imageScale(.large)
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
