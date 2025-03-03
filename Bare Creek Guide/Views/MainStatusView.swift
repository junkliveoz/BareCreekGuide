//
//  MainStatusView.swift
//  Bare Creek Safety Officer
//
//  Created by Adam on 22/2/2025.
//

import SwiftUI
import UIKit

struct ParkStatusView: View {
    @ObservedObject private var viewModel: ParkStatusViewModel
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(viewModel: ParkStatusViewModel = ParkStatusViewModel()) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                StatusHeaderView(
                    currentTime: currentTime,
                    parkStatus: viewModel.parkStatus,
                    currentWeather: viewModel.currentWeather,
                    isLoading: viewModel.isLoading,
                    isInitialLoad: viewModel.isInitialLoad,
                    twoDayRainTotal: viewModel.twoDayRainTotal
                )
                
                WeatherDataView(
                    currentWeather: viewModel.currentWeather,
                    weatherHistory: viewModel.weatherHistory,
                    isLoading: viewModel.isLoading
                )
            }
            .padding(.horizontal)
        }
        .refreshable {
            await viewModel.fetchLatestWeatherAsync()
        }
        .onReceive(timer) { input in
            currentTime = input
        }
        .navigationTitle("Bare Creek Status")
    }
}

#Preview {
    ParkStatusView()
}
