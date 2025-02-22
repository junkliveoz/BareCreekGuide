//
//  StatusHeaderView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct StatusHeaderView: View {
    let currentTime: Date
    let parkStatus: ParkStatus
    let currentWeather: WeatherData?
    let isLoading: Bool
    let isInitialLoad: Bool
    let twoDayRainTotal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(spacing: 16) {
                // Image section with time overlay
                ZStack {
                    if isInitialLoad {
                        // Show a loading placeholder during initial load
                        Rectangle()
                            .fill(Color(.systemGray5))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    } else {
                        Image(parkStatus.imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                    }
                    
                    // Time overlay
                    Text(currentTime, style: .time)
                        .font(.system(size: 46, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 30)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.4))
                        )
                }
                
                // Status heading and message
                if isInitialLoad {
                    VStack(alignment: .leading, spacing: 12) {
                        // Loading placeholder
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Loading park status...")
                                .font(.system(size: 24, weight: .bold))
                        }
                        Text("Fetching current conditions...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(parkStatus.title)
                            .font(.system(size: 24, weight: .bold))
                        messageContent
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                        
                        // Rain warning (shows when there's been some rain but not enough for wet conditions)
                        if shouldShowRainWarning {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("There has been rain. If your tyres leave a mark, stay off the trails.")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
        }
    }
    
    // Show rain warning if there's been some rain (> 0) but not enough for wet conditions (≤ 7mm)
    private var shouldShowRainWarning: Bool {
        return twoDayRainTotal > 0 && twoDayRainTotal <= 7.0 && parkStatus != .wetConditions
    }
    
    @ViewBuilder
    private var messageContent: some View {
        switch parkStatus {
        case .closed:
            let closingTime = Calendar.current.component(.month, from: Date()) >= 10 ||
            Calendar.current.component(.month, from: Date()) <= 3 ? "7pm" : "5pm"
            Text("Will be open between 6am and \(closingTime)")
            
        case .perfectConditions:
            Text("Ideal conditions, double black trails will open with a safety officer present.")
            
        case .windyConditions:
            Text("Park Open, conditions are too windy for the double black features.")
            
        case .strongWinds:
            Text("The wind is strong enough for the jump trails, recommend pump track and flow lines only.")
            
        case .extremeWinds:
            Text("The wind conditions are too strong to be on the trails.")
            
        case .wetConditions:
            HStack(spacing: 4) {
                Text("The park is probably to wet to ride.")
                Text("here")
                    .foregroundColor(.blue)
                    .underline()
                    .onTapGesture {
                        if let url = URL(string: "https://www.instagram.com/barecreektrailstatus/") {
                            UIApplication.shared.open(url)
                        }
                    }
            }
        }
    }
}
