//
//  WatchConnectivityManager.swift
//  Bare Creek Guide
//
//  Created by Adam on 7/4/2025.
//  Updated to fix session lifecycle issues on 7/4/2025
//

import SwiftUI
import WatchConnectivity

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    private var session: WCSession? = WCSession.isSupported() ? WCSession.default : nil
    
    // Reference to the main park status view model
    private weak var parkStatusViewModel: ParkStatusViewModelProtocol?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setParkStatusViewModel(_ viewModel: ParkStatusViewModelProtocol) {
        self.parkStatusViewModel = viewModel
        
        // Send initial data to watch if possible
        sendParkStatusToWatch()
    }
    
    private func setupWatchConnectivity() {
        guard let session = session else {
            print("Watch connectivity not supported on this device")
            return
        }
        
        session.delegate = self
        session.activate()
        print("Watch connectivity session activated")
    }
    
    // Send current park status to watch
    func sendParkStatusToWatch() {
        guard let session = session, session.activationState == .activated else {
            print("Watch connectivity session not activated")
            return
        }
        
        guard let viewModel = parkStatusViewModel, let currentWeather = viewModel.currentWeather else {
            print("No park status data available to send to watch")
            return
        }
        
        // Create data dictionary to send to watch
        var statusData: [String: Any] = [:]
        
        // Park status
        statusData["parkStatus"] = viewModel.parkStatus.title
        
        // Status color
        switch viewModel.parkStatus {
        case .perfectConditions:
            statusData["statusColor"] = "green"
        case .windyConditions:
            statusData["statusColor"] = "yellow"
        case .strongWinds:
            statusData["statusColor"] = "orange"
        case .extremeWinds, .closed:
            statusData["statusColor"] = "red"
        case .wetConditions:
            statusData["statusColor"] = "blue"
        }
        
        // Wind data
        statusData["windSpeed"] = String(format: "%.1f", currentWeather.wind_gust_kmh)
        statusData["windDirection"] = currentWeather.wind_dir
        
        // Rain data
        statusData["rainTotal"] = String(format: "%.1f", viewModel.twoDayRainTotal)
        
        // Send data to watch - use all available methods to ensure delivery
        
        // 1. Application context (best for background updates)
        do {
            try session.updateApplicationContext(statusData)
            print("Updated application context for watch: \(statusData)")
        } catch {
            print("Error sending app context to watch: \(error)")
        }
        
        // 2. Transfer file if watch is reachable (more reliable for larger data)
        if session.isReachable {
            // Send via direct message for immediate update
            session.sendMessage(statusData, replyHandler: { reply in
                print("Watch acknowledged message with reply: \(reply)")
            }) { error in
                print("Error sending message to watch: \(error)")
            }
            print("Sent direct message to watch: \(statusData)")
        } else {
            print("Watch is not reachable for direct messages")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    // Required for WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("WCSession activated: \(activationState.rawValue)")
                // Send current status once activated
                self.sendParkStatusToWatch()
            }
        }
    }
    
    // Handle messages from watch
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        DispatchQueue.main.async {
            // Check if watch is requesting weather update
            if let request = message["request"] as? String, request == "weatherUpdate" {
                guard let viewModel = self.parkStatusViewModel, let currentWeather = viewModel.currentWeather else {
                    // No data available, send empty response
                    replyHandler([:])
                    return
                }
                
                // Create response data
                var statusData: [String: Any] = [:]
                
                // Park status
                statusData["parkStatus"] = viewModel.parkStatus.title
                
                // Status color
                switch viewModel.parkStatus {
                case .perfectConditions:
                    statusData["statusColor"] = "green"
                case .windyConditions:
                    statusData["statusColor"] = "yellow"
                case .strongWinds:
                    statusData["statusColor"] = "orange"
                case .extremeWinds, .closed:
                    statusData["statusColor"] = "red"
                case .wetConditions:
                    statusData["statusColor"] = "blue"
                }
                
                // Wind data
                statusData["windSpeed"] = String(format: "%.1f", currentWeather.wind_gust_kmh)
                statusData["windDirection"] = currentWeather.wind_dir
                
                // Rain data
                statusData["rainTotal"] = String(format: "%.1f", viewModel.twoDayRainTotal)
                
                // Send response
                replyHandler(statusData)
                print("Sent weather update response to watch: \(statusData)")
            } else {
                // Unknown request, send empty response
                replyHandler([:])
                print("Received unknown message from watch: \(message)")
            }
        }
    }
    
    // Required methods for iOS - use conditional compilation
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("WCSession deactivated")
        // Reactivate the session - this is important when switching between multiple watches
        session.activate()
    }
    #endif
    
    // Handle regular message receipt (no reply handler)
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            print("Received message from watch (no reply expected): \(message)")
            // Process message if needed
        }
    }
}
