//
//  WatchViewModel.swift
//  Bare Creek Guide
//
//  Created by Adam on 7/4/2025.
//  Updated to fix session delegate issues and improve data freshness
//

import SwiftUI
import WatchConnectivity

class WatchViewModel: NSObject, ObservableObject {
    // Published properties that will update the UI
    @Published var parkStatus: String = "Loading..."
    @Published var statusColor: Color = .gray
    @Published var windSpeed: String = "--"
    @Published var windDirection: String = "--"
    @Published var rainTotal: String = "--"
    @Published var lastUpdated: Date = Date()
    @Published var isLoading: Bool = true
    @Published var isDataFresh: Bool = false
    
    // Watch connectivity session for communication with iPhone
    private var session: WCSession?
    
    // Timeout timer
    private var loadingTimer: Timer?
    
    // Refresh timer
    private var refreshTimer: Timer?
    
    override init() {
        super.init()
        
        // Immediately show cached data to avoid blank screen
        loadCachedData()
        
        // Then set up connectivity and request fresh data
        setupWatchConnectivity()
        requestUpdate()
        
        // Setup periodic refresh
        setupRefreshTimer()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
            print("Watch connectivity session activated")
        } else {
            print("Watch connectivity not supported on this device")
        }
    }
    
    private func setupRefreshTimer() {
        // Refresh every 5 minutes while app is open
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.requestUpdate()
        }
    }
    
    // Request updated data from the phone
    func requestUpdate() {
        // Cancel any existing loading timer
        loadingTimer?.invalidate()
        
        self.isLoading = true
        
        // Setup loading timeout (10 seconds)
        loadingTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            if self.isLoading {
                print("Update request timed out")
                self.isLoading = false
                
                // Ensure we have at least cached data showing
                if self.parkStatus == "Loading..." {
                    self.loadCachedData()
                }
            }
        }
        
        guard let session = session, session.activationState == .activated else {
            print("Watch connectivity session not activated")
            // No connection to phone, load cached data if available
            loadCachedData()
            return
        }
        
        if session.isReachable {
            // Request fresh data from the phone
            print("Requesting weather update from phone")
            session.sendMessage(["request": "weatherUpdate"], replyHandler: { [weak self] response in
                print("Received weather update from phone: \(response)")
                DispatchQueue.main.async {
                    self?.updateFromResponse(response)
                    self?.saveDataToCache(response)
                    self?.isLoading = false
                    
                    // Cancel the loading timer since we got data
                    self?.loadingTimer?.invalidate()
                }
            }, errorHandler: { [weak self] error in
                print("Error requesting update: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.loadCachedData()
                    self?.isLoading = false
                }
            })
        } else {
            print("Phone not reachable for direct messages")
            // Phone not reachable, load cached data
            loadCachedData()
        }
    }
    
    // Update the view model from a response dictionary
    private func updateFromResponse(_ response: [String: Any]) {
        if let statusString = response["parkStatus"] as? String {
            self.parkStatus = statusString
            print("Updated parkStatus: \(statusString)")
        }
        
        if let colorString = response["statusColor"] as? String {
            self.statusColor = colorFromString(colorString)
            print("Updated statusColor: \(colorString)")
        }
        
        if let windSpeedValue = response["windSpeed"] as? String {
            self.windSpeed = windSpeedValue
            print("Updated windSpeed: \(windSpeedValue)")
        }
        
        if let windDirValue = response["windDirection"] as? String {
            self.windDirection = windDirValue
            print("Updated windDirection: \(windDirValue)")
        }
        
        if let rainValue = response["rainTotal"] as? String {
            self.rainTotal = rainValue
            print("Updated rainTotal: \(rainValue)")
        }
        
        self.lastUpdated = Date()
        self.isDataFresh = true
        self.isLoading = false
    }
    
    // Convert a color string to Color
    private func colorFromString(_ colorString: String) -> Color {
        switch colorString {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "orange":
            return .orange
        case "red":
            return .red
        case "blue":
            return .blue
        default:
            return .gray
        }
    }
    
    // Save data to local cache
    private func saveDataToCache(_ data: [String: Any]) {
        let userDefaults = UserDefaults.standard
        for (key, value) in data {
            if let stringValue = value as? String {
                userDefaults.set(stringValue, forKey: key)
            }
        }
        userDefaults.set(Date(), forKey: "lastUpdated")
        print("Saved data to local cache")
    }
    
    // Load cached data if available
    private func loadCachedData() {
        print("Loading cached data")
        let userDefaults = UserDefaults.standard
        
        if let status = userDefaults.string(forKey: "parkStatus") {
            self.parkStatus = status
            print("Loaded cached parkStatus: \(status)")
        }
        
        if let colorString = userDefaults.string(forKey: "statusColor") {
            self.statusColor = colorFromString(colorString)
            print("Loaded cached statusColor: \(colorString)")
        }
        
        if let windSpeed = userDefaults.string(forKey: "windSpeed") {
            self.windSpeed = windSpeed
            print("Loaded cached windSpeed: \(windSpeed)")
        }
        
        if let windDir = userDefaults.string(forKey: "windDirection") {
            self.windDirection = windDir
            print("Loaded cached windDirection: \(windDir)")
        }
        
        if let rain = userDefaults.string(forKey: "rainTotal") {
            self.rainTotal = rain
            print("Loaded cached rainTotal: \(rain)")
        }
        
        if let lastUpdate = userDefaults.object(forKey: "lastUpdated") as? Date {
            self.lastUpdated = lastUpdate
            print("Loaded cached lastUpdated: \(lastUpdate)")
        }
        
        // Data from cache is not considered fresh
        self.isDataFresh = false
        self.isLoading = false
    }
    
    // Get time ago string for last updated
    func timeAgoString() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUpdated, relativeTo: Date())
    }
    
    // Get formatted time of last update
    func formattedLastUpdatedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: lastUpdated)
    }
    
    // Check if data is stale (older than 15 minutes)
    func isDataStale() -> Bool {
        let staleThreshold: TimeInterval = 15 * 60 // 15 minutes
        return Date().timeIntervalSince(lastUpdated) > staleThreshold
    }
    
    // Clean up timers when app goes to background
    func cleanup() {
        loadingTimer?.invalidate()
        loadingTimer = nil
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

// MARK: - WCSessionDelegate
extension WatchViewModel: WCSessionDelegate {
    // Required for WCSessionDelegate on watchOS
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            if let error = error {
                print("WCSession activation failed: \(error.localizedDescription)")
            } else {
                print("WCSession activated: \(activationState.rawValue)")
                self.requestUpdate()
            }
        }
    }
    
    // Handle incoming messages from iPhone
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("Received message from iPhone: \(message)")
        DispatchQueue.main.async { [weak self] in
            self?.updateFromResponse(message)
            self?.saveDataToCache(message)
        }
    }
    
    // Handle application context updates
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("Received application context from iPhone: \(applicationContext)")
        DispatchQueue.main.async { [weak self] in
            self?.updateFromResponse(applicationContext)
            self?.saveDataToCache(applicationContext)
        }
    }
}
