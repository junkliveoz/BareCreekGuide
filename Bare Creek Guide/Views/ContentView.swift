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
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Park Status Tab
            ParkStatusView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "cloud.sun.fill")
                    Text("Conditions")
                }
                .tag(0)
            
            // Trails Tab
            TrailsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "mountain.2.fill")
                    Text("Trails")
                }
                .tag(1)
            
            // Info Tab
            InfoView()
                .tabItem {
                    Image(systemName: "info.circle.fill")
                    Text("Info")
                }
                .tag(2)
        }
        .accentColor(Color("AccentColor"))
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
