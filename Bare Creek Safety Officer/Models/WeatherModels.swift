//
//  WeatherModels.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 23/2/2025.
//

import SwiftUI

struct WeatherResponse: Codable {
    let observations: Observations
}

struct Observations: Codable {
    let data: [WeatherData]
}

struct WeatherData: Codable, Identifiable, Hashable {
    let id = UUID()
    let wind_gust_kmh: Double
    let wind_dir: String
    let local_date_time_full: String
    let rain_trace_string: String
    
    var rain_since_9am: Double {
        if rain_trace_string == "-" {
            return 0.0
        }
        return Double(rain_trace_string) ?? 0.0
    }
    
    enum CodingKeys: String, CodingKey {
        case wind_gust_kmh = "gust_kmh"
        case wind_dir
        case local_date_time_full
        case rain_trace_string = "rain_trace"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(local_date_time_full)
    }
    
    static func == (lhs: WeatherData, rhs: WeatherData) -> Bool {
        return lhs.local_date_time_full == rhs.local_date_time_full
    }
}

enum ParkStatus {
    case closed
    case perfectConditions     // <15 kmh wind
    case windyConditions       // 15-30 kmh wind
    case strongWinds           // 30-45 kmh wind
    case extremeWinds          // >45 kmh wind
    case wetConditions         // >7mm rain over 2 days
    
    var title: String {
        switch self {
        case .closed:
            return "Park is Closed"
        case .perfectConditions:
            return "Perfect Conditions"
        case .windyConditions:
            return "Windy Conditions"
        case .strongWinds:
            return "Strong Winds"
        case .extremeWinds:
            return "Extreme Winds"
        case .wetConditions:
            return "Wet Conditions"
        }
    }
    
    var imageName: String {
        switch self {
        case .closed:
            return "BareCreek-Night"
        case .perfectConditions:
            return "BareCreek-Open"
        case .windyConditions:
            return "BareCreek-Wind"
        case .strongWinds:
            return "BareCreek-StrongWind"
        case .extremeWinds:
            return "BareCreek-ExtremeWind"
        case .wetConditions:
            return "BareCreek-Wet"
        }
    }
}
