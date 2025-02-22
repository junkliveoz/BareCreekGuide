//
//  ParkStatusViewModel.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI
import Combine

class ParkStatusViewModel: ObservableObject {
    @Published var currentWeather: WeatherData?
    @Published var weatherHistory: [WeatherData] = []
    @Published var isLoading = true
    @Published var error: Error?
    @Published var isInitialLoad = true
    @Published var twoDayRainTotal: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    private let weatherService: WeatherServiceProtocol
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
    
    private var isParkOpenBasedOnTime: Bool {
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
                    self?.updateWeatherData(weatherDataArray)
                    self?.calculateTwoDayRainTotal(weatherDataArray)
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
            isLoading = false
            isInitialLoad = false
        } catch {
            self.error = error
            isLoading = false
            isInitialLoad = false
        }
    }
    
    private func updateWeatherData(_ newData: [WeatherData]) {
        // Update current weather with the latest reading
        currentWeather = newData.first
        
        // Update history with new data while preserving order
        let updatedHistory = newData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        weatherHistory = Array(updatedHistory.prefix(maxHistoryCount))
        
        // Ensure UI updates
        objectWillChange.send()
    }
    
    private func calculateTwoDayRainTotal(_ weatherData: [WeatherData]) {
        let sortedData = weatherData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        
        // Get the latest valid rain reading for today (ignoring blank/"-" values)
        var todayRain: Double = 0.0
        var foundValidReading = false
        
        for entry in sortedData {
            // Skip entries with blank/"-" rain values
            if entry.rain_trace_string == "-" {
                continue
            }
            
            if let rainValue = Double(entry.rain_trace_string), rainValue >= 0 {
                todayRain = rainValue
                foundValidReading = true
                break
            }
        }
        
        // If we didn't find any valid reading, default to 0
        if !foundValidReading {
            todayRain = 0.0
        }
        
        // Calculate yesterday's date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        
        var yesterdayRain: Double = 0.0
        
        if let currentEntry = sortedData.first,
           let currentDate = dateFormatter.date(from: currentEntry.local_date_time_full) {
            
            let calendar = Calendar.current
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                // If we can't calculate yesterday, just use today's rain
                twoDayRainTotal = todayRain
                return
            }
            
            // Get yesterday's date components
            let yesterdayYear = calendar.component(.year, from: yesterday)
            let yesterdayMonth = calendar.component(.month, from: yesterday)
            let yesterdayDay = calendar.component(.day, from: yesterday)
            
            // Find the highest valid rain reading from yesterday
            for entry in sortedData {
                // Skip entries with blank/"-" rain values
                if entry.rain_trace_string == "-" {
                    continue
                }
                
                if let entryDate = dateFormatter.date(from: entry.local_date_time_full),
                   let rainValue = Double(entry.rain_trace_string) {
                    let entryYear = calendar.component(.year, from: entryDate)
                    let entryMonth = calendar.component(.month, from: entryDate)
                    let entryDay = calendar.component(.day, from: entryDate)
                    
                    // Check if the entry is from yesterday
                    if entryYear == yesterdayYear && entryMonth == yesterdayMonth && entryDay == yesterdayDay {
                        // Get the highest rain value from yesterday
                        if rainValue > yesterdayRain {
                            yesterdayRain = rainValue
                        }
                    }
                }
            }
        }
        
        // Calculate the total
        twoDayRainTotal = todayRain + yesterdayRain
        print("Rain calculation: Today: \(todayRain), Yesterday: \(yesterdayRain), Total: \(twoDayRainTotal)")
    }
}
