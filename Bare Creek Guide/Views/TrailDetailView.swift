//
//  TrailDetailView.swift
//  Bare Creek Guide
//
//  Updated for MVVM architecture on 11/3/2025.
//  Improved state sharing on 11/3/2025.
//  Added rain warning on 11/3/2025.
//  Fixed dark mode support on 18/3/2025.
//

import SwiftUI
import MapKit

struct TrailDetailView: View {
    @StateObject private var viewModel: TrailDetailViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) private var colorScheme
    
    init(trail: Binding<Trail>, parkStatus: ParkStatus) {
        // Initialize the view model with the trail and status
        // We don't need to pass the binding anymore since we're using the shared TrailManager
        _viewModel = StateObject(wrappedValue: TrailDetailViewModel(
            trail: trail.wrappedValue,
            parkStatus: parkStatus
        ))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Trail name header - now uses the computed property
                Text(viewModel.trail.name)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Hero image/map with rounded corners and buttons
                ZStack(alignment: .top) {
                    // Either show the image or the map
                    if viewModel.showMap {
                        // Map view
                        Map(initialPosition: MapCameraPosition.region(viewModel.mapRegion)) {
                            // Annotation for the trail
                            Annotation(
                                viewModel.trail.name,
                                coordinate: viewModel.trail.coordinates,
                                anchor: .bottom
                            ) {
                                VStack {
                                    Image(systemName: "mappin")
                                        .font(.title)
                                        .foregroundColor(viewModel.trail.difficulty.color)
                                    
                                    Text(viewModel.trail.name)
                                        .font(.caption)
                                        .foregroundColor(.black)
                                        .padding(4)
                                        .background(Color.white.opacity(0.8))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .mapStyle(.hybrid)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    } else {
                        // Trail image
                        Image(viewModel.trail.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Top row with map toggle and favorite buttons
                    HStack {
                        // Map toggle button
                        Button(action: {
                            viewModel.toggleMapView()
                        }) {
                            Image(systemName: viewModel.showMap ? "photo" : "map")
                                .foregroundColor(.white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(12)
                        
                        Spacer()
                        
                        // Favorite button
                        Button(action: {
                            viewModel.toggleFavorite()
                        }) {
                            Image(systemName: viewModel.trail.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(viewModel.trail.isFavorite ? .red : .white)
                                .padding(10)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(12)
                    }
                }
                .padding(.horizontal)
                
                // Difficulty and Direction row
                HStack {
                    // Difficulty
                    HStack(spacing: 6) {
                        viewModel.trail.difficulty.displayIcon
                            .imageScale(.medium)
                        
                        Text(viewModel.trail.difficulty.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Direction
                    HStack(spacing: 6) {
                        Image(systemName: viewModel.trail.direction.icon)
                        Text(viewModel.trail.direction.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Status section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: viewModel.currentStatus.icon)
                            .foregroundColor(viewModel.currentStatus.color)
                            .font(.system(size: 20))
                        
                        Text("Current Status: \(viewModel.currentStatus.rawValue)")
                            .font(.headline)
                            .foregroundColor(viewModel.currentStatus.color)
                    }
                    
                    // Rain warning - only show when there's recent rain
                    if viewModel.shouldShowRainWarning {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text("Recent rain detected - Never ride wet trails!")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.black.opacity(0.4))
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Location section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Location", icon: "mappin.and.ellipse")
                    
                    Text(viewModel.trail.details.location)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Overview section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Overview", icon: "info.circle")
                    
                    Text(viewModel.trail.details.overview)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Suitable bikes section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Suitable Bikes", icon: "bicycle")
                    
                    HStack(spacing: 10) {
                        ForEach(viewModel.trail.details.suitableBikes, id: \.self) { bike in
                            Text(bike.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
                
                // Local tips section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Local Tips", icon: "lightbulb")
                    
                    Text(viewModel.trail.details.localsTips)
                        .font(.body)
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading:
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .foregroundColor(colorScheme == .dark ? .white : .black)
            }
        )
    }
}

struct SectionHeaderView: View {
    let title: String
    let icon: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color("AccentColor"))
            
            Text(title)
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
        }
        .padding(.top, 6)
    }
}

#Preview {
    let exampleTrail = Trail.predefinedTrails[0]
    
    return NavigationView {
        TrailDetailView(
            trail: .constant(exampleTrail),
            parkStatus: .perfectConditions
        )
    }
    .preferredColorScheme(.dark) // Preview in dark mode
}
