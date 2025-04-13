//
//  ParkStatusViewModel.swift
//  Bare Creek Guide
//

import SwiftUI
import Combine

class ParkStatusViewModel: ObservableObject {
    // Shared instance
    static let shared = ParkStatusViewModel()
    
    // Published properties to update the UI
    @Published var weatherHistory: [WeatherData] = []
    @Published var currentWeather: WeatherData?
    @Published var isLoading: Bool = true
    @Published var isInitialLoad: Bool = true
    @Published var parkStatus: ParkStatus = .closed
    @Published var twoDayRainTotal: Double = 0.0
    
    // Weather service
    private let weatherService = WeatherService.shared
    
    // Cancellables for Combine
    private var cancellables = Set<AnyCancellable>()
    
    // Timer for refreshing data
    private var refreshTimer: Timer?
    
    // Initialize the view model
    init() {
        print("ParkStatusViewModel initialized")
        setupTimer()
        fetchLatestWeather()
    }
    
    // Set up a timer to refresh the data
    private func setupTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.fetchLatestWeather()
        }
    }
    
    // Fetch the latest weather data
    func fetchLatestWeather() {
        isLoading = true
        
        weatherService.fetchWeatherData()
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("Weather data fetch completed")
                case .failure(let error):
                    print("Weather data fetch failed: \(error.localizedDescription)")
                }
                self.isLoading = false
                self.isInitialLoad = false
            }, receiveValue: { weatherData in
                self.updateWeatherData(weatherData)
                self.calculateTwoDayRainTotal(weatherData)
            })
            .store(in: &cancellables)
    }
    
    // Fetch the latest weather data asynchronously
    func fetchLatestWeatherAsync() async {
        // Set loading state
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Fetch weather data
            let weatherData = try await weatherService.fetchWeatherDataAsync()
            
            // Update UI on main thread
            await MainActor.run {
                // Update weather data
                updateWeatherData(weatherData)
                calculateTwoDayRainTotal(weatherData)
                
                // Update loading states
                isLoading = false
                isInitialLoad = false
            }
        } catch {
            print("Async weather fetch failed: \(error.localizedDescription)")
            
            // Update loading states on main thread
            await MainActor.run {
                isLoading = false
                isInitialLoad = false
            }
        }
    }
    
    // Update the weather data
    func updateWeatherData(_ weatherData: [WeatherData]) {
        // Update weather history with all data
        weatherHistory = weatherData
        
        // Set current weather to the most recent reading
        if let latest = weatherData.first {
            currentWeather = latest
        }
    }
    
    // Calculate the two-day rain total based on BOM's 9am reset cycle
    func calculateTwoDayRainTotal(_ weatherData: [WeatherData]) {
        guard !weatherData.isEmpty else { return }
        
        // Sort data by time, most recent first
        let sortedData = weatherData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        
        // Print all rain data for debugging
        print("All rain readings from newest to oldest:")
        for reading in sortedData {
            print("Time: \(reading.local_date_time_full), Rain: \(reading.rain_trace_string), Converted: \(reading.rain_since_9am)")
        }
        
        // Get the most recent reading for current rain
        let mostRecentReading = sortedData[0]
        let currentRainSince9am = mostRecentReading.rain_since_9am
        
        // Format for date parsing
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        // Find the rain reading from 9am
        var nineAMReading = 0.0
        var nineAMReadingFound = false
        
        for reading in sortedData {
            // Try to find any reading with 9am in the time (ignore minutes)
            if reading.local_date_time_full.contains("0900") {
                nineAMReading = reading.rain_since_9am
                nineAMReadingFound = true
                print("Found 9AM reading with exact match: \(reading.local_date_time_full), value: \(nineAMReading)")
                break
            }
        }
        
        // If no exact 9am reading found, look for any time between 9:00 and 9:30
        if !nineAMReadingFound {
            for reading in sortedData {
                if reading.local_date_time_full.prefix(10).hasSuffix("09") &&
                   Int(reading.local_date_time_full.dropFirst(10).prefix(2)) ?? 99 < 30 {
                    nineAMReading = reading.rain_since_9am
                    nineAMReadingFound = true
                    print("Found 9AM-ish reading: \(reading.local_date_time_full), value: \(nineAMReading)")
                    break
                }
            }
        }
        
        // Simple string matching fallback for 9.0mm reading
        if !nineAMReadingFound {
            for reading in sortedData {
                if reading.rain_trace_string == "9.0" {
                    nineAMReading = 9.0  // Use directly converted value to avoid any issues
                    nineAMReadingFound = true
                    print("Found reading with 9.0mm rain: \(reading.local_date_time_full)")
                    break
                }
            }
        }
        
        // Calculate the total rain for the past ~48 hours
        let total = currentRainSince9am + nineAMReading
        print("Final calculation: Current rain (\(currentRainSince9am)) + 9AM reading (\(nineAMReading)) = \(total)mm")
        
        // Update the property
        self.twoDayRainTotal = total
        print("Set twoDayRainTotal to \(self.twoDayRainTotal)mm")
        
        // Update park status based on new calculation
        updateParkStatus()
    }
    
    // Check if the park is open based on time of day
    var isParkOpenBasedOnTime: Bool {
        let calendar = Calendar.current
        let now = Date()
        let hour = calendar.component(.hour, from: now)
        
        // Park is open from 6 AM to 5 PM in winter, 7 PM in summer
        let closingHour: Int
        
        // Check if we're in summer months (October to March)
        let month = calendar.component(.month, from: now)
        if month >= 10 || month <= 3 {
            // Summer hours (close at 7 PM)
            closingHour = 19
        } else {
            // Winter hours (close at 5 PM)
            closingHour = 17
        }
        
        // Park is open if hour is between 6 AM and closing hour
        return hour >= 6 && hour < closingHour
    }
    
    // Update the park status based on wind and rain conditions
    private func updateParkStatus() {
        // Default to closed outside of operating hours
        guard isParkOpenBasedOnTime else {
            parkStatus = .closed
            return
        }
        
        // Check wind and rain thresholds
        if twoDayRainTotal > 7.0 {
            // Too wet to ride
            parkStatus = .wetConditions
            print("Park status set to wet conditions due to rain total of \(twoDayRainTotal)mm")
        } else if let weather = currentWeather {
            // Check wind conditions
            let windGust = weather.wind_gust_kmh
            
            if windGust > 45.0 {
                parkStatus = .extremeWinds
            } else if windGust > 30.0 {
                parkStatus = .strongWinds
            } else if windGust > 15.0 {
                parkStatus = .windyConditions
            } else {
                parkStatus = .perfectConditions
            }
            print("Park status set to \(parkStatus) due to wind gust of \(windGust)km/h")
        } else {
            // Default if no weather data
            parkStatus = .closed
            print("Park status set to closed due to lack of weather data")
        }
    }
    
    // Deinitialize the view model
    deinit {
        // Clean up the timer
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        // Clean up any cancellables
        cancellables.removeAll()
    }
}

// Extend ParkStatusViewModel to conform to the protocol
extension ParkStatusViewModel: ParkStatusViewModelProtocol {}

extension ParkStatusViewModel {
    // Setup watch connectivity
    func setupWatchConnectivity() {
        // Register with the connectivity manager
        WatchConnectivityManager.shared.setParkStatusViewModel(self)
        
        // Add a subscription to send updates to the watch when values change
        $parkStatus
            .combineLatest($currentWeather, $twoDayRainTotal)
            .sink { [weak self] _ in
                // When key values change, update the watch
                WatchConnectivityManager.shared.sendParkStatusToWatch()
            }
            .store(in: &cancellables)
    }
}
