//
//  TrailViewModels.swift
//  Bare Creek Guide
//
//  Created on 11/3/2025.
//  Improved for better state sharing on 11/3/2025
//  Updated with rain warning feature on 11/3/2025
//

import SwiftUI
import MapKit
import Combine

/// ViewModel for the main TrailsView
class TrailsViewModel: ObservableObject {
    // TrailManager for trail data - shared across all ViewModels
    @Published var trailManager = TrailManager.shared
    
    // Dependencies
    private var parkStatusViewModel: ParkStatusViewModel
    
    // Search and filter state
    @Published var searchText = ""
    @Published var selectedDifficulty: TrailDifficulty? = nil
    @Published var selectedDirection: TrailDirection? = nil
    @Published var selectedStatus: TrailStatus? = nil
    @Published var selectedBike: SuitableBike? = nil
    @Published var showFavoritesOnly = false
    @Published var showFilterSheet = false
    @Published var sortOption: SortOption = .alphabetical
    @Published var showSortMenu = false
    @Published var viewMode: ViewMode = .list
    
    // Cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    enum ViewMode {
        case list
        case map
    }
    
    enum SortOption: String, CaseIterable {
        case alphabetical = "Alphabetical"
        case status = "By Status"
        case direction = "By Direction"
        case difficulty = "By Difficulty"
        case favorites = "Favorites First"
    }
    
    init(parkStatusViewModel: ParkStatusViewModel) {
        self.parkStatusViewModel = parkStatusViewModel
        
        // Set up reactive bindings to ensure UI updates when trail data changes
        self.trailManager.$trails
            .sink { [weak self] _ in
                // Trigger UI update when trails change
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Check if any filters are active
    var hasActiveFilters: Bool {
        selectedDifficulty != nil || selectedDirection != nil || selectedStatus != nil ||
        selectedBike != nil || showFavoritesOnly
    }
    
    /// Reset all filters to default values
    func resetFilters() {
        selectedDifficulty = nil
        selectedDirection = nil
        selectedStatus = nil
        selectedBike = nil
        showFavoritesOnly = false
    }
    
    /// Get the current park status
    var parkStatus: ParkStatus {
        return parkStatusViewModel.parkStatus
    }
    
    /// Get filtered and sorted trails based on current filters and sort option
    var filteredTrails: [Trail] {
        var filteredTrails = trailManager.trails
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            filteredTrails = filteredTrails.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply favorites filter if needed
        if showFavoritesOnly {
            filteredTrails = filteredTrails.filter { $0.isFavorite }
        }
        
        // Apply difficulty filter if needed
        if let selectedDifficulty = selectedDifficulty {
            filteredTrails = filteredTrails.filter { $0.difficulty == selectedDifficulty }
        }
        
        // Apply direction filter if needed
        if let selectedDirection = selectedDirection {
            filteredTrails = filteredTrails.filter { $0.direction == selectedDirection }
        }
        
        // Apply status filter if needed
        if let selectedStatus = selectedStatus {
            filteredTrails = filteredTrails.filter { $0.currentStatus(for: parkStatus) == selectedStatus }
        }
        
        // Apply bike filter if needed
        if let selectedBike = selectedBike {
            filteredTrails = filteredTrails.filter { $0.details.suitableBikes.contains(selectedBike) }
        }
        
        // Apply sorting
        switch sortOption {
        case .alphabetical:
            return filteredTrails.sorted { $0.name < $1.name }
        case .status:
            return filteredTrails.sorted { $0.currentStatus(for: parkStatus).rawValue < $1.currentStatus(for: parkStatus).rawValue }
        case .direction:
            return filteredTrails.sorted { $0.direction.rawValue < $1.direction.rawValue }
        case .difficulty:
            return filteredTrails.sorted {
                let difficultyOrder: [TrailDifficulty] = [.green, .blue, .blackDiamond, .doubleBlackDiamond, .proline]
                let idx1 = difficultyOrder.firstIndex(of: $0.difficulty) ?? 0
                let idx2 = difficultyOrder.firstIndex(of: $1.difficulty) ?? 0
                return idx1 < idx2
            }
        case .favorites:
            return filteredTrails.sorted { $0.isFavorite && !$1.isFavorite }
        }
    }
}

/// ViewModel for the TrailsMapView
class TrailsMapViewModel: NSObject, ObservableObject {
    // Reference to the shared TrailManager
    @ObservedObject var trailManager = TrailManager.shared
    
    @Published var parkStatus: ParkStatus
    @Published var mapStyleType: MapStyleType = .hybrid
    @Published var cameraPosition: MapCameraPosition
    @Published var location: CLLocation?
    
    private var locationManager: CLLocationManager!
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property to get trails from the shared manager
    var trails: [Trail] {
        return trailManager.trails
    }
    
    // Enum to handle map style
    enum MapStyleType {
        case standard
        case hybrid
    }
    
    init(trails: [Trail], parkStatus: ParkStatus) {
        self.parkStatus = parkStatus
        
        // Initialize camera position to park center
        self.cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: -33.71560, longitude: 151.20650),
                span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
            )
        )
        
        // Call super.init before setting up the locationManager
        super.init()
        
        // Set up location manager
        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10
        
        // Listen for changes to trails in TrailManager
        self.trailManager.$trails
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func toggleMapStyle() {
        mapStyleType = mapStyleType == .hybrid ? .standard : .hybrid
    }
    
    /// Center the map on the user's location
    func centerOnUserLocation() {
        if let location = location?.coordinate {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                )
            )
        }
    }
    
    /// Reset the map to show all trails
    func resetMapRegion() {
        setOptimalRegion()
    }
    
    /// Calculate the optimal region to show all trails
    func setOptimalRegion() {
        // Default to park center if no visible trails
        if trails.isEmpty {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: -33.71560, longitude: 151.20650),
                    span: MKCoordinateSpan(latitudeDelta: 0.003, longitudeDelta: 0.003)
                )
            )
            return
        }
        
        // Calculate the bounding box of all trail coordinates
        var minLat = trails[0].coordinates.latitude
        var maxLat = trails[0].coordinates.latitude
        var minLon = trails[0].coordinates.longitude
        var maxLon = trails[0].coordinates.longitude
        
        for trail in trails {
            minLat = min(minLat, trail.coordinates.latitude)
            maxLat = max(maxLat, trail.coordinates.latitude)
            minLon = min(minLon, trail.coordinates.longitude)
            maxLon = max(maxLon, trail.coordinates.longitude)
        }
        
        // Calculate center point
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        // Calculate span with some padding
        let latDelta = (maxLat - minLat) * 1.3
        let lonDelta = (maxLon - minLon) * 1.3
        
        // Set the region
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
                span: MKCoordinateSpan(
                    latitudeDelta: max(latDelta, 0.001), // Ensure minimum zoom level
                    longitudeDelta: max(lonDelta, 0.001)
                )
            )
        )
    }
}

// Extension for CLLocationManagerDelegate methods
extension TrailsMapViewModel: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            locationManager.stopUpdatingLocation()
            location = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

/// ViewModel for the TrailDetailView
class TrailDetailViewModel: ObservableObject {
    // Reference to the shared TrailManager
    @ObservedObject var trailManager = TrailManager.shared
    
    // Reference to the shared ParkStatusViewModel to get rain data
    @ObservedObject var parkStatusViewModel = ParkStatusViewModel.shared
    
    // Published properties for the view to observe
    @Published var trailID: UUID
    @Published var parkStatus: ParkStatus
    @Published var showMap = false
    @Published var mapRegion: MKCoordinateRegion
    
    // Cancellables for subscription management
    private var cancellables = Set<AnyCancellable>()
    
    // Computed property to get the latest trail data
    var trail: Trail {
        // Try to find the trail in the manager's collection
        if let trail = trailManager.trails.first(where: { $0.id == trailID }) {
            return trail
        }
        
        // Fallback (should rarely happen)
        return initialTrail
    }
    
    // Computed property to determine if should show rain warning
    var shouldShowRainWarning: Bool {
        // Get two-day rain total from ParkStatusViewModel
        let rainTotal = parkStatusViewModel.twoDayRainTotal
        
        // Show rain warning if there's been some rain (> 0) but not enough for wet conditions (≤ 7mm)
        // and the current park status isn't already set to wetConditions
        return rainTotal > 0 && rainTotal <= 7.0 && parkStatus != .wetConditions
    }
    
    // Store initial trail in case we need it
    private let initialTrail: Trail
    
    init(trail: Trail, parkStatus: ParkStatus) {
        self.trailID = trail.id
        self.parkStatus = parkStatus
        self.initialTrail = trail
        
        // Initialize map region centered on the trail
        self.mapRegion = MKCoordinateRegion(
            center: trail.coordinates,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )
        
        // Listen for changes to trails in TrailManager
        self.trailManager.$trails
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        // Listen for changes to weather/rain data
        self.parkStatusViewModel.$twoDayRainTotal
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Toggle between showing the map and the trail image
    func toggleMapView() {
        withAnimation {
            showMap.toggle()
        }
    }
    
    /// Toggle favorite status for this trail
    func toggleFavorite() {
        // Use the TrailManager to toggle the favorite state
        // This ensures all views see the same state
        trailManager.toggleFavorite(for: trailID)
    }
    
    /// Get the current status of the trail based on park conditions
    var currentStatus: TrailStatus {
        return trail.currentStatus(for: parkStatus)
    }
}
