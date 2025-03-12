//
//  TrailsView.swift
//  Bare Creek Guide
//
//  Updated for MVVM architecture on 11/3/2025.
//  Fixed map filtering support on 12/3/2025.
//  Updated onChange modifiers for iOS 17 on 12/3/2025.
//

import SwiftUI

struct TrailsView: View {
    @StateObject private var viewModel: TrailsViewModel
    @StateObject private var mapViewModel: TrailsMapViewModel
    
    init(parkStatusViewModel: ParkStatusViewModel) {
        // Use StateObject to create the ViewModels
        let trailsViewModel = TrailsViewModel(parkStatusViewModel: parkStatusViewModel)
        _viewModel = StateObject(wrappedValue: trailsViewModel)
        
        // Initialize map view model with the filtered trails
        _mapViewModel = StateObject(wrappedValue: TrailsMapViewModel(
            trails: trailsViewModel.filteredTrails,
            parkStatus: trailsViewModel.parkStatus
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar section
            VStack(spacing: 8) {
                // Search bar only
                SearchBar(text: $viewModel.searchText, placeholder: "Search trails")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: viewModel.searchText) {
                        updateMapFilters()
                    }
                
                // Active filters summary (if any)
                if viewModel.hasActiveFilters {
                    ActiveFiltersView(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            
            // Main content area - switch between list and map with fade transition
            ZStack {
                if viewModel.viewMode == .list {
                    // Trails list view
                    TrailListView(viewModel: viewModel)
                        .transition(.opacity)
                }
                
                if viewModel.viewMode == .map {
                    // Trails map view
                    TrailsMapView(viewModel: mapViewModel)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
        }
        // Individual observers for filter changes - iOS 17 syntax
        .onChange(of: viewModel.selectedDifficulty) {
            updateMapFilters()
        }
        .onChange(of: viewModel.selectedDirection) {
            updateMapFilters()
        }
        .onChange(of: viewModel.selectedStatus) {
            updateMapFilters()
        }
        .onChange(of: viewModel.selectedBike) {
            updateMapFilters()
        }
        .onChange(of: viewModel.showFavoritesOnly) {
            updateMapFilters()
        }
        .onChange(of: viewModel.sortOption) {
            updateMapFilters()
        }
        .navigationTitle("Trails")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Sort button with fade animation
                    Button(action: {
                        if viewModel.viewMode == .list {
                            viewModel.showSortMenu = true
                        }
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .imageScale(.large)
                            .foregroundColor(Color("AccentColor"))
                            .opacity(viewModel.viewMode == .list ? (viewModel.sortOption != .alphabetical ? 1.0 : 0.7) : 0.0)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
                    }
                    .disabled(viewModel.viewMode != .list)
                    .confirmationDialog("Sort Trails", isPresented: $viewModel.showSortMenu, titleVisibility: .visible) {
                        ForEach(TrailsViewModel.SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                viewModel.sortOption = option
                            }
                        }
                    }
                    
                    // Filter button
                    Button(action: {
                        viewModel.showFilterSheet = true
                    }) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .imageScale(.large)
                            .foregroundColor(Color("AccentColor"))
                            .opacity(viewModel.hasActiveFilters ? 1.0 : 0.7)
                    }
                    
                    // View mode toggle with icon fade transition
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.viewMode = viewModel.viewMode == .list ? .map : .list
                        }
                    }) {
                        ZStack {
                            Image(systemName: "map")
                                .imageScale(.large)
                                .foregroundColor(Color("AccentColor"))
                                .opacity(viewModel.viewMode == .list ? 1.0 : 0.0)
                            
                            Image(systemName: "list.bullet")
                                .imageScale(.large)
                                .foregroundColor(Color("AccentColor"))
                                .opacity(viewModel.viewMode == .map ? 1.0 : 0.0)
                        }
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $viewModel.showFilterSheet) {
            FilterSheetView(viewModel: viewModel)
                .onDisappear {
                    // Update map filters when the filter sheet is dismissed
                    updateMapFilters()
                }
        }
        .onAppear {
            // Initial update of map filters
            updateMapFilters()
        }
    }
    
    // Helper function to update map filters
    private func updateMapFilters() {
        mapViewModel.updateFilteredTrails(viewModel.filteredTrails)
    }
}

#Preview {
    NavigationView {
        TrailsView(parkStatusViewModel: ParkStatusViewModel())
    }
}
