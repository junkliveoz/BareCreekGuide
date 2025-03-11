//
//  ParkStatusViewModel.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI
import Combine

class ParkStatusViewModel: ObservableObject {
    // Add shared instance for access from AppDelegate
    static let shared = ParkStatusViewModel()
    
    @Published var currentWeather: WeatherData?
    @Published var weatherHistory: [WeatherData] = []
    @Published var isLoading = true
    @Published var error: Error?
    @Published var isInitialLoad = true
    @Published var twoDayRainTotal: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let weatherService: WeatherServiceProtocol
    private let notificationManager = NotificationManager.shared
    private let maxHistoryCount = 10
    private var refreshTimer: Timer?
    
    init(weatherService: WeatherServiceProtocol = WeatherService.shared) {
        self.weatherService = weatherService
        setupAutoRefresh()
        Task {
            await fetchLatestWeatherAsync()
        }
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    var parkStatus: ParkStatus {
        if !isParkOpenBasedOnTime {
            return .closed
        }
        
        guard let weather = currentWeather else {
            return .closed
        }
        
        // Check for wet conditions first
        if twoDayRainTotal > 7.0 {
            return .wetConditions
        }
        
        // Check wind conditions
        let windGust = weather.wind_gust_kmh
        
        if windGust <= 15.0 {
            return .perfectConditions
        } else if windGust <= 30.0 {
            return .windyConditions
        } else if windGust <= 45.0 {
            return .strongWinds
        } else {
            return .extremeWinds
        }
    }
    
    // Make isParkOpenBasedOnTime public so it can be accessed by AppDelegate
    var isParkOpenBasedOnTime: Bool {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.hour, .month], from: now)
        let currentHour = components.hour ?? 0
        let currentMonth = components.month ?? 0
        
        let closingTime = (currentMonth >= 10 || currentMonth <= 3) ? 19 : 17 // 7 PM or 5 PM
        
        return currentHour >= 6 && currentHour < closingTime
    }
    
    private func setupAutoRefresh() {
        // Refresh every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchLatestWeatherAsync()
            }
        }
    }
    
    func fetchLatestWeather() {
        isLoading = true
        
        weatherService.fetchWeatherData()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    self?.isInitialLoad = false
                    if case .failure(let error) = completion {
                        self?.error = error
                    }
                },
                receiveValue: { [weak self] weatherDataArray in
                    guard let self = self else { return }
                    self.updateWeatherData(weatherDataArray)
                    self.calculateTwoDayRainTotal(weatherDataArray)
                    self.processNotifications()
                }
            )
            .store(in: &cancellables)
    }
    
    @MainActor
    func fetchLatestWeatherAsync() async {
        isLoading = true
        
        do {
            let weatherDataArray = try await weatherService.fetchWeatherDataAsync()
            updateWeatherData(weatherDataArray)
            calculateTwoDayRainTotal(weatherDataArray)
            processNotifications()
            isLoading = false
            isInitialLoad = false
        } catch {
            self.error = error
            isLoading = false
            isInitialLoad = false
        }
    }
    
    // Changed from private to public for background access
    public func updateWeatherData(_ newData: [WeatherData]) {
        // Update current weather with the latest reading
        currentWeather = newData.first
        
        // Update history with new data while preserving order
        let updatedHistory = newData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        weatherHistory = Array(updatedHistory.prefix(maxHistoryCount))
        
        // Ensure UI updates
        objectWillChange.send()
    }
    
    private func processNotifications() {
        notificationManager.processWeatherUpdate(
            currentWeather: currentWeather,
            parkStatus: parkStatus,
            twoDayRainTotal: twoDayRainTotal,
            isParkOpen: isParkOpenBasedOnTime
        )
    }
    
    public func calculateTwoDayRainTotal(_ weatherData: [WeatherData]) {
        let sortedData = weatherData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        
        // STEP 1: Find today's 9 AM reading, which represents rain accumulated since 9 AM yesterday
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var nineAMRain: Double = 0.0
        
        // Look for today's 9 AM reading
        if let currentEntry = sortedData.first,
           let currentDate = dateFormatter.date(from: currentEntry.local_date_time_full) {
            
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: currentDate)
            let currentMonth = calendar.component(.month, from: currentDate)
            let currentDay = calendar.component(.day, from: currentDate)
            
            // Find the 9 AM reading for today
            for entry in sortedData {
                if let entryDate = dateFormatter.date(from: entry.local_date_time_full) {
                    let entryHour = calendar.component(.hour, from: entryDate)
                    let entryMinute = calendar.component(.minute, from: entryDate)
                    let entryYear = calendar.component(.year, from: entryDate)
                    let entryMonth = calendar.component(.month, from: entryDate)
                    let entryDay = calendar.component(.day, from: entryDate)
                    
                    // Check if this is today's 9 AM reading
                    if entryYear == currentYear && entryMonth == currentMonth && entryDay == currentDay &&
                       entryHour == 9 && entryMinute == 0 {
                        
                        // Get the 9 AM rain value
                        if entry.rain_trace_string != "-" {
                            nineAMRain = Double(entry.rain_trace_string) ?? 0.0
                        }
                        break
                    }
                }
            }
        }
        
        // STEP 2: Find the highest rain reading after 9 AM today
        var highestRainSince9AM: Double = 0.0
        var nineAMTimestamp: String? = nil
        
        // First, find the 9 AM timestamp
        for entry in sortedData {
            if let entryDate = dateFormatter.date(from: entry.local_date_time_full) {
                let entryHour = Calendar.current.component(.hour, from: entryDate)
                let entryMinute = Calendar.current.component(.minute, from: entryDate)
                
                if entryHour == 9 && entryMinute == 0 {
                    nineAMTimestamp = entry.local_date_time_full
                    break
                }
            }
        }
        
        // Then find the highest rain value after 9 AM
        if let nineAMTimestamp = nineAMTimestamp {
            for entry in sortedData {
                // Only consider entries after 9 AM
                if entry.local_date_time_full > nineAMTimestamp && entry.rain_trace_string != "-" {
                    if let rainValue = Double(entry.rain_trace_string), rainValue > highestRainSince9AM {
                        highestRainSince9AM = rainValue
                    }
                }
            }
        }
        
        // Calculate the total
        twoDayRainTotal = nineAMRain + highestRainSince9AM
        print("Rain calculation: 9 AM reading: \(nineAMRain), Highest since 9 AM: \(highestRainSince9AM), Total: \(twoDayRainTotal)")
    }
}
