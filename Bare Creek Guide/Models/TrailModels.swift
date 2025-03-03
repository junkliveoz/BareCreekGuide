//
//  TrailModels.swift
//  Bare Creek Guide
//
//  Created by Adam on 27/2/2025.
//

import SwiftUI

enum TrailDifficulty: String, CaseIterable, Identifiable {
    case green = "Green"
    case blue = "Blue"
    case blackDiamond = "Black Diamond"
    case doubleBlackDiamond = "Double Black Diamond"
    case proline = "Proline"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .green:
            return .green
        case .blue:
            return .blue
        case .blackDiamond:
            return .black
        case .doubleBlackDiamond:
            return .black
        case .proline:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .green:
            return "circle.fill"
        case .blue:
            return "square.fill"
        case .blackDiamond:
            return "diamond.fill"
        case .doubleBlackDiamond:
            return "diamond.fill"
        case .proline:
            return "hexagon.fill"
        }
    }
    
    var displayIcon: some View {
        Group {
            if self == .doubleBlackDiamond {
                HStack(spacing: -5) {
                    Image(systemName: "diamond.fill")
                    Image(systemName: "diamond.fill")
                }
                .foregroundColor(self.color)
            } else {
                Image(systemName: self.icon)
                    .foregroundColor(self.color)
            }
        }
    }
}

enum TrailDirection: String, CaseIterable, Identifiable {
    case downhill = "Downhill"
    case uphill = "Uphill"
    case multiDirection = "Multi-direction"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .downhill:
            return "arrow.down"
        case .uphill:
            return "arrow.up"
        case .multiDirection:
            return "arrow.up.arrow.down"
        }
    }
}

enum TrailStatus: String {
    case open = "Open"
    case openWithSafetyOfficer = "Open if Safety Officer onsite"
    case caution = "Caution"
    case closed = "Closed"
    
    var color: Color {
        switch self {
        case .open:
            return .green
        case .openWithSafetyOfficer:
            return .blue
        case .caution:
            return .orange
        case .closed:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .open:
            return "checkmark.circle.fill"
        case .openWithSafetyOfficer:
            return "person.fill.checkmark"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .closed:
            return "xmark.circle.fill"
        }
    }
}

struct Trail: Identifiable {
    let id = UUID()
    let name: String
    let difficulty: TrailDifficulty
    let direction: TrailDirection
    let imageName: String
    var statusMap: [ParkStatus: TrailStatus]
    
    func currentStatus(for parkStatus: ParkStatus) -> TrailStatus {
        return statusMap[parkStatus] ?? .closed
    }
    
    static let allTrails: [Trail] = [
        Trail(
            name: "Pump Track",
            difficulty: .blue,
            direction: .multiDirection,
            imageName: "Trails-PumpTrack",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .open,
                .extremeWinds: .open,
                .wetConditions: .open
            ]
        ),
        Trail(
            name: "Falcon Oath",
            difficulty: .green,
            direction: .downhill,
            imageName: "Trails-FalconOath",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .open,
                .extremeWinds: .open,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Mild",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-Mild",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Medium",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-Medium",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Spicy",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Spicy",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .openWithSafetyOfficer,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Social Distancing",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-SocialDistancing",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Livewire",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Livewire",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .openWithSafetyOfficer,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Trash Panda",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-TrashPanda",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Bin Chicken",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-BinChicken",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Short Circuit",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-ShortCircuit",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Power Trip",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-PowerTrip",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Darcside",
            difficulty: .proline,
            direction: .downhill,
            imageName: "Trails-Darcside",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Blackout",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Blackout",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Watts Up",
            difficulty: .proline,
            direction: .downhill,
            imageName: "Trails-WattsUp",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Four Seconds",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-FourSeconds",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "The Butler",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-TheButler",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Lighten Up",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-LightenUp",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        ),
        Trail(
            name: "Power Back",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-PowerBack",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ]
        )
    ]
}
