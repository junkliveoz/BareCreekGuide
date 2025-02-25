//
//  CurrentWeatherSection.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct CurrentWeatherSection: View {
    let weather: WeatherData?
    
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
                        Text("Direction")
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
                    
                    // Rain Box
                    VStack {
                        Text("Rain")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Spacer()
                        
                        VStack(spacing: 2) {
                            // Display the raw value from BOM if it's a "-", otherwise format it
                            if weather.rain_trace_string == "-" {
                                Text("-")
                                    .font(.title2)
                            } else {
                                Text("\(String(format: "%.1f", weather.rain_since_9am))")
                                    .font(.title2)
                            }
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
