//
//  TrailsMapView.swift
//  Bare Creek Guide
//
//  Updated for MVVM architecture on 11/3/2025.
//

import SwiftUI
import MapKit

struct TrailsMapView: View {
    @StateObject private var viewModel: TrailsMapViewModel
    
    init(trails: [Trail], parkStatus: ParkStatus) {
        _viewModel = StateObject(wrappedValue: TrailsMapViewModel(
            trails: trails,
            parkStatus: parkStatus
        ))
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // The map with new iOS 17 API
            Map(position: $viewModel.cameraPosition, interactionModes: .all) {
                // Add user location marker if available
                if let location = viewModel.location {
                    Marker(coordinate: location.coordinate) {
                        Image(systemName: "figure.walk")
                            .foregroundColor(.blue)
                    }
                }
                
                // Add trail markers
                ForEach(viewModel.trails) { trail in
                    Annotation(
                        trail.name,
                        coordinate: trail.coordinates,
                        anchor: .bottom
                    ) {
                        // Custom marker view instead of default pin
                        NavigationLink(destination: TrailDetailView(
                            trail: TrailManager.shared.binding(for: trail),
                            parkStatus: viewModel.parkStatus
                        )) {
                            TrailMarkerView(
                                trail: trail,
                                currentStatus: trail.currentStatus(for: viewModel.parkStatus)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .mapStyle(viewModel.mapStyleType == .hybrid ? .hybrid : .standard)
            .edgesIgnoringSafeArea(.all)
            
            // Control buttons
            VStack(spacing: 10) {
                // Toggle Map Type button
                Button(action: {
                    viewModel.toggleMapStyle()
                }) {
                    Image(systemName: viewModel.mapStyleType == .hybrid ? "map" : "map.fill")
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                // Center on User button
                Button(action: {
                    viewModel.centerOnUserLocation()
                }) {
                    Image(systemName: "location")
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
                
                // Reset to Park Center button
                Button(action: {
                    viewModel.resetMapRegion()
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .padding(10)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            .padding()
        }
        .onAppear {
            // Request location permissions when the view appears
            viewModel.requestLocationPermission()
            
            // If we have trails, calculate the best region to show all of them
            if !viewModel.trails.isEmpty {
                viewModel.setOptimalRegion()
            }
        }
    }
}

/// Custom map marker view for trails
struct TrailMarkerView: View {
    let trail: Trail
    let currentStatus: TrailStatus
    
    var body: some View {
        VStack(spacing: 0) {
            // Trail name label
            Text(trail.name)
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.8))
                .cornerRadius(10)
                .shadow(radius: 1)
            
            // Trail image in a circle
            Image(trail.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(trail.difficulty.color, lineWidth: 3)
                )
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 2)
                )
                
            // Small status indicator
            Circle()
                .fill(currentStatus.color)
                .frame(width: 12, height: 12)
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
                .offset(y: -4)
        }
    }
}

#Preview {
    TrailsMapView(
        trails: Trail.predefinedTrails,
        parkStatus: .perfectConditions
    )
}
