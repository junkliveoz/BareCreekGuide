//
//  ParkStatusViewModelProtocol.swift
//  Bare Creek Guide
//
//  Created for cross-platform compatibility
//

import Foundation
import SwiftUI

// Protocol used by both iOS and watchOS apps
protocol ParkStatusViewModelProtocol: AnyObject {
    var parkStatus: ParkStatus { get }
    var currentWeather: WeatherData? { get }
    var twoDayRainTotal: Double { get }
}
