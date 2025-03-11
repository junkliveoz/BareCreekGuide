//
//  TrailsView.swift
//  Bare Creek Guide
//
//  Updated for MVVM architecture on 11/3/2025.
//

import SwiftUI

struct TrailsView: View {
    @StateObject private var viewModel: TrailsViewModel
    
    init(parkStatusViewModel: ParkStatusViewModel) {
        // Use StateObject to create the ViewModel
        _viewModel = StateObject(wrappedValue: TrailsViewModel(parkStatusViewModel: parkStatusViewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search bar section
            VStack(spacing: 8) {
                // Search bar only
                SearchBar(text: $viewModel.searchText, placeholder: "Search trails")
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
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
                    TrailsMapView(
                        trails: viewModel.filteredTrails,
                        parkStatus: viewModel.parkStatus
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.viewMode)
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
        }
    }
}

#Preview {
    NavigationView {
        TrailsView(parkStatusViewModel: ParkStatusViewModel())
    }
}
