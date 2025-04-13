//
//  WatchContentView.swift
//  Bare Creek Watch Watch App
//
//  Created by Adam on 7/4/2025.
//  Updated to rename from ContentView to avoid naming conflicts
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var viewModel: WatchViewModel
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 12) {
                    // Title with Last Reading Time
                    VStack(spacing: 2) {
                        Text("Park Status as of \(viewModel.formattedLastUpdatedTime())")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        // Show stale data warning if needed
                        if viewModel.isDataStale() {
                            Text("Data may be outdated")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.bottom, 5)
                    
                    // Status Card
                    statusCard
                    
                    // Wind Card
                    windCard
                    
                    // Rain Card
                    rainCard
                }
                .padding(.horizontal)
            }
            .navigationTitle("Bare Creek")
        }
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.2))
                                .frame(width: 50, height: 50)
                        )
                }
            }
        )
        .onAppear {
            viewModel.requestUpdate()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .refreshable {
            isRefreshing = true
            viewModel.requestUpdate()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second for UI feedback
            isRefreshing = false
        }
    }
    
    // Park Status Card
    private var statusCard: some View {
        VStack(spacing: 2) {
            Text("PARK STATUS")
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(alignment: .center) {
                Circle()
                    .fill(viewModel.statusColor)
                    .frame(width: 14, height: 14)
                
                Text(viewModel.parkStatus)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // Wind Information Card
    private var windCard: some View {
        VStack(spacing: 2) {
            Text("WIND")
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(viewModel.windSpeed)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("km/h")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text(viewModel.windDirection)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("direction")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    // Rain Information Card
    private var rainCard: some View {
        VStack(spacing: 2) {
            Text("RAIN (48h)")
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Text("\(viewModel.rainTotal)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("mm")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.leading, -5)
                
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
}

#Preview {
    WatchContentView()
        .environmentObject(WatchViewModel())
}
