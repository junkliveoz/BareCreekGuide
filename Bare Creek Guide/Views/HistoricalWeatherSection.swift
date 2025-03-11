//
//  HistoricalWeatherSection.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//  Updated to fix unused variable warning on 4/3/2025
//

import SwiftUI

struct HistoricalWeatherSection: View {
    let weatherHistory: [WeatherData]
    let isLoading: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent Readings")
                .font(.headline)
                .padding(.bottom, 5)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {
                // Fixed column widths - removed unused dirWidth variable
                let timeWidth: CGFloat = 70
                let windWidth: CGFloat = 85
                let rainWidth: CGFloat = 70
                
                // Table Header with properly aligned icons
                HStack(spacing: 0) {
                    // Time column
                    Image(systemName: "clock")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: timeWidth, alignment: .leading)
                    
                    Spacer()
                    
                    // Wind column - align left where the values start
                    Image(systemName: "wind")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: windWidth, alignment: .leading)
                    
                    /**
                    // Direction column
                    Image(systemName: "location.north")
                        .rotationEffect(.degrees(45))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: dirWidth, alignment: .center)
                    **/
                    
                    // Rain column
                    Image(systemName: "cloud.rain")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: rainWidth, alignment: .leading)
                }
                .padding(.bottom, 5)
                
                // Table data rows
                ForEach(weatherHistory.prefix(10)) { reading in
                    HStack(spacing: 0) {
                        // Time
                        Text(formatDateTime(reading.local_date_time_full))
                            .font(.subheadline)
                            .frame(width: timeWidth, alignment: .leading)
                        
                        Spacer()
                        
                        // Wind gust with unit
                        Text("\(String(format: "%.1f", reading.wind_gust_kmh)) km/h")
                            .font(.subheadline)
                            .frame(width: windWidth, alignment: .leading)
                        
                        /**
                        // Wind direction
                        Text(reading.wind_dir)
                            .font(.subheadline)
                            .frame(width: dirWidth, alignment: .center)
                        **/
                        
                        // Rain with unit
                        if reading.rain_trace_string == "-" {
                            Text("-")
                                .font(.subheadline)
                                .frame(width: rainWidth, alignment: .leading)
                        } else {
                            Text("\(String(format: "%.1f", reading.rain_since_9am)) mm")
                                .font(.subheadline)
                                .frame(width: rainWidth, alignment: .leading)
                        }
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formatDateTime(_ dateTimeString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        
        if let date = formatter.date(from: dateTimeString) {
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: date)
        }
        return dateTimeString
    }
}
