//
//  WeatherService.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 22/2/2025.
//

import SwiftUI
import Combine

protocol WeatherServiceProtocol {
    func fetchWeatherData() -> AnyPublisher<[WeatherData], Error>
    func fetchWeatherDataAsync() async throws -> [WeatherData]
}

class WeatherService: WeatherServiceProtocol {
    static let shared = WeatherService()
    private let bomURL = "http://www.bom.gov.au/fwo/IDN60901/IDN60901.94759.json"
    private var updateTimer: Timer?
    
    func fetchWeatherData() -> AnyPublisher<[WeatherData], Error> {
        guard let url = URL(string: bomURL) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        return URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .tryMap { response -> [WeatherData] in
                guard !response.observations.data.isEmpty else {
                    throw URLError(.cannotParseResponse)
                }
                return response.observations.data
                    .prefix(50)
                    .sorted { $0.local_date_time_full > $1.local_date_time_full }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    func fetchWeatherDataAsync() async throws -> [WeatherData] {
        guard let url = URL(string: bomURL) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WeatherResponse.self, from: data)
        
        guard !response.observations.data.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        
        // Ensure consistent sorting
        return response.observations.data
            .prefix(50)
            .sorted { $0.local_date_time_full > $1.local_date_time_full }
    }
}
