//
//  StatusMessageView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct StatusMessageView: View {
    let parkStatus: ParkStatus
    let twoDayRainTotal: Double
    
    var body: some View {
        VStack(spacing: 12) {
            Text(parkStatus.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            messageContent
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            // Rain warning if applicable
            if shouldShowRainWarning {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.yellow)
                    Text("There has been rain. If your tyres leave a mark, stay off the trails.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.yellow)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.black.opacity(0.4))
                .cornerRadius(8)
                .padding(.top, 8)
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
                Text("The park is probably to wet to ride. If your tyres leave a mark, stay off the trails.")
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
