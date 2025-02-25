//
//  ContentView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 22/2/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ParkStatusView()
                .navigationTitle("Bare Creek Status")
        }
    }
}

#Preview {
    ContentView()
}
