//
//  WeatherDataView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct WeatherDataView: View {
    let currentWeather: WeatherData?
    let weatherHistory: [WeatherData]
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            CurrentWeatherSection(weather: currentWeather)
            
            HistoricalWeatherSection(
                weatherHistory: weatherHistory,
                isLoading: isLoading
            )
        }
        .padding(.bottom, 20)
    }
}
