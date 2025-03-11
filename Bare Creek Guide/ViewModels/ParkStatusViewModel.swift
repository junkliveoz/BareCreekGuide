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
        
        // Sort data by time, most recent first (should already be sorted but ensuring)
        let sortedData = weatherData.sorted { $0.local_date_time_full > $1.local_date_time_full }
        
        // Get the most recent reading
        let mostRecentReading = sortedData[0]
        
        // Format for date parsing
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        // Variables to track rain
        var currentRainSince9am: Double = 0.0  // Rain since 9am today
        var nineAMReading: Double = 0.0       // The 9am reading (which is yesterday's total)
        var foundNineAMReading = false
        
        // First, set current rain to the most recent reading
        currentRainSince9am = mostRecentReading.rain_since_9am
        print("Current rain since 9am: \(currentRainSince9am)mm")
        
        // Now find today's 9am reading, which gives us yesterday's rain total
        for reading in sortedData {
            guard let readingTime = formatter.date(from: reading.local_date_time_full) else {
                continue
            }
            
            let calendar = Calendar.current
            let components = calendar.dateComponents([.hour, .minute], from: readingTime)
            
            // Look for a reading at approximately 9am
            // This accounts for readings that might be a few minutes off from exactly 9:00
            let isAround9AM = components.hour == 9 && components.minute! < 15
            
            if isAround9AM {
                nineAMReading = reading.rain_since_9am
                foundNineAMReading = true
                print("Found 9am reading: \(nineAMReading)mm at time: \(reading.local_date_time_full)")
                break
            }
        }
        
        // If we couldn't find a 9am reading, use a reasonable fallback
        if !foundNineAMReading {
            print("No 9am reading found, using fallback calculation")
            
            // Find the oldest reading from today as a fallback
            // Since BOM resets at 9am, the best approximation is the earliest reading after 9am
            
            let calendar = Calendar.current
            var oldestReadingToday: WeatherData?
            var oldestReadingTime: Date?
            
            for reading in sortedData.reversed() { // Start from oldest in our dataset
                guard let readingTime = formatter.date(from: reading.local_date_time_full),
                      let mostRecentTime = formatter.date(from: mostRecentReading.local_date_time_full) else {
                    continue
                }
                
                // Check if this reading is from the same day as the most recent one
                let isSameDay = calendar.isDate(readingTime, inSameDayAs: mostRecentTime)
                
                // If it's from the same day and after 9am, it could be our fallback
                let components = calendar.dateComponents([.hour], from: readingTime)
                if isSameDay && components.hour! >= 9 {
                    if oldestReadingTime == nil || readingTime < oldestReadingTime! {
                        oldestReadingTime = readingTime
                        oldestReadingToday = reading
                    }
                }
            }
            
            if let oldestReading = oldestReadingToday {
                nineAMReading = oldestReading.rain_since_9am
                print("Using fallback 9am reading: \(nineAMReading)mm at time: \(oldestReading.local_date_time_full)")
            } else {
                print("No suitable fallback reading found, using 0mm for 9am reading")
            }
        }
        
        // Calculate the total rain for the past ~48 hours
        // Current rain since 9am + the 9am reading (which covers the previous 24 hours)
        let total = currentRainSince9am + nineAMReading
        print("Two-day rain total: \(total)mm (Current: \(currentRainSince9am)mm, 9am Reading: \(nineAMReading)mm)")
        
        // Update the property
        self.twoDayRainTotal = total
        
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
