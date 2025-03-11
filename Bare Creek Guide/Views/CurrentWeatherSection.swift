//
//  CurrentWeatherSection.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//  Updated to show 48-hour rain total on 12/3/2025
//

import SwiftUI

struct CurrentWeatherSection: View {
    let weather: WeatherData?
    let twoDayRainTotal: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            if let weather = weather {
                HStack(spacing: 12) {
                    // Wind Gust Box
                    VStack {
                        Text("Wind Gust")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(String(format: "%.1f", weather.wind_gust_kmh))")
                                .font(.title2)
                            Text("km/h")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                    
                    // Wind Direction Box
                    VStack {
                        Text("Wind Direction")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        Text(weather.wind_dir)
                            .font(.title2)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                    
                    // Rain Box - Updated to show 48-hour total
                    VStack {
                        Text("Rain (48h)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            Text("\(String(format: "%.1f", twoDayRainTotal))")
                                .font(.title2)
                                .foregroundColor(twoDayRainTotal > 7.0 ? .red : .primary)
                            Text("mm")
                                .font(.subheadline)
                        }
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemBackground))
                    )
                }
            } else {
                HStack {
                    Text("Loading weather data...")
                        .foregroundColor(.gray)
                    ProgressView()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        )
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
    
    return CurrentWeatherSection(weather: sampleWeather, twoDayRainTotal: 9.4)
}
