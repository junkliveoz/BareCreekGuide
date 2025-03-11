//
//  WeatherDataView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//  Updated to pass the 48-hour rain total on 12/3/2025
//

import SwiftUI

struct WeatherDataView: View {
    let currentWeather: WeatherData?
    let weatherHistory: [WeatherData]
    let isLoading: Bool
    let twoDayRainTotal: Double
    
    var body: some View {
        VStack(spacing: 20) {
            CurrentWeatherSection(
                weather: currentWeather,
                twoDayRainTotal: twoDayRainTotal
            )
            
            HistoricalWeatherSection(
                weatherHistory: weatherHistory,
                isLoading: isLoading
            )
        }
        .padding(.bottom, 20)
    }
}

#Preview {
    // Sample data for preview
    let sampleWeather = WeatherData(
        wind_gust_kmh: 15.2,
        wind_dir: "SW",
        local_date_time_full: "20250312105500",
        rain_trace_string: "2.2"
    )
    
    return WeatherDataView(
        currentWeather: sampleWeather,
        weatherHistory: [sampleWeather],
        isLoading: false,
        twoDayRainTotal: 9.4
    )
}
