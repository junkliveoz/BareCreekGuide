//
//  InfoView.swift
//  Bare Creek Guide
//
//  Created by Adam on 27/2/2025.
//  Updated on 3/3/2025.
//  Updated on 4/3/2025 for simplified UI and satellite map view.
//  Updated with correct park coordinates.
//  Updated to fix deprecated MapKit APIs on 4/3/2025.
//

import SwiftUI
import MapKit

struct InfoView: View {
    @State private var position = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -33.71648, longitude: 151.20828),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    )
    
    @State private var showMap = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Park Location
                VStack(alignment: .leading, spacing: 10) {
                    Text("Park Location")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if showMap {
                        // Updated Map implementation using iOS 17 MapKit API
                        Map(position: $position) {
                            Marker("Bare Creek Bike Park", coordinate: CLLocationCoordinate2D(latitude: -33.71648, longitude: 151.20828))
                                .tint(.red)
                        }
                        .mapStyle(.hybrid)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onAppear {
                            // Slight adjustment to ensure map centers correctly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                position = .region(
                                    MKCoordinateRegion(
                                        center: CLLocationCoordinate2D(latitude: -33.71648, longitude: 151.20828),
                                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                    )
                                )
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bare Creek Bike Park")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("2819 Crozier Road")
                            .font(.subheadline)
                        Text("Belrose NSW 2085")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        openMapsWithDirections()
                    }) {
                        HStack {
                            Image(systemName: "map.fill")
                            Text("Get Directions")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                
                // Opening Hours
                VStack(alignment: .leading, spacing: 10) {
                    Text("Opening Hours")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(Color("AccentColor"))
                        Text("7am to 5pm (7PM in AEST)")
                            .font(.subheadline)
                    }
                    
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .foregroundColor(Color("AccentColor"))
                        Text("7 days a week")
                            .font(.subheadline)
                    }
                }
                .padding(.horizontal)
                
                // Conditions
                VStack(alignment: .leading, spacing: 10) {
                    Text("Conditions")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Bare Creek is generally considered perfect conditions when not wet and wind gust 15kmh or below. The open or closed status of individual trails can change at short notice subject to weather conditions (wind and rain). The full park may also be closed due to weather or for maintenance activities.")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
                // Parking
                VStack(alignment: .leading, spacing: 10) {
                    Text("Parking")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Parking for up to 40 cars is available. Overflow parking available on nearby streets. Please ride in via the shared bike/walking path.")
                        .font(.subheadline)
                }
                .padding(.horizontal)
                
                // Safety Officer
                VStack(alignment: .leading, spacing: 10) {
                    Text("Safety Officer")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Want to see the Zapper open more often?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("We're on the lookout for more volunteer Safety Officers.")
                        .font(.subheadline)
                    
                    Text("Requirements:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.top, 4)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Over 18")
                        Text("• AusCycling membership")
                        Text("• First Aid Certification")
                        Text("• Be prepared to handle any incidents at the park whilst on duty")
                    }
                    .font(.subheadline)
                    
                    Text("Parents of younger riders are encouraged to get involved.")
                        .font(.subheadline)
                        .padding(.top, 4)
                    
                    Text("If interested contact Trail Care info@trailcare.com.au")
                        .font(.subheadline)
                        .foregroundColor(Color("AccentColor"))
                }
                .padding(.horizontal)
                
                // Links and Resources
                VStack(alignment: .leading, spacing: 10) {
                    Text("Links & Resources")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 0) {
                        LinkButton(icon: "globe", title: "Official Website", url: "https://www.barecreekbikepark.com")
                        Divider()
                        LinkButton(icon: "camera", title: "Instagram", url: "https://www.instagram.com/barecreektrailstatus/")
                        Divider()
                        LinkButton(icon: "map", title: "Trail Maps", url: "https://www.trailforks.com/region/bare-creek-bike-park-43315/")
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Bare Creek Info")
        .onAppear {
            showMap = true
        }
        .onDisappear {
            showMap = false
        }
    }
    
    func openMapsWithDirections() {
        let latitude: CLLocationDegrees = -33.71648
        let longitude: CLLocationDegrees = 151.20828
        
        let regionDistance: CLLocationDistance = 1000
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Bare Creek Bike Park"
        mapItem.openInMaps(launchOptions: options)
    }
}

struct ParkLocation: Identifiable {
    let id = UUID()
    let coordinate = CLLocationCoordinate2D(latitude: -33.71648, longitude: 151.20828)
}

struct LinkButton: View {
    let icon: String
    let title: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
        }
    }
}

#Preview {
    InfoView()
}
