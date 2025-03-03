//
//  TrailsView.swift
//  Bare Creek Guide
//
//  Created by Adam on 27/2/2025.
//

import SwiftUI

struct TrailsView: View {
    @ObservedObject var viewModel: ParkStatusViewModel
    @State private var searchText = ""
    @State private var selectedDifficulty: TrailDifficulty? = nil
    @State private var selectedDirection: TrailDirection? = nil
    @State private var selectedStatus: TrailStatus? = nil
    @State private var showFilterSheet = false
    @State private var sortOption: SortOption = .alphabetical
    @State private var showSortMenu = false
    
    enum SortOption: String, CaseIterable {
        case alphabetical = "Alphabetical"
        case status = "By Status"
        case direction = "By Direction"
        case difficulty = "By Difficulty"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search, filter and sort bar
                HStack {
                    // Search bar
                    SearchBar(text: $searchText, placeholder: "Search trails")
                    
                    // Sort button
                    Button(action: {
                        showSortMenu = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .imageScale(.medium)
                            Text("Sort")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(sortOption != .alphabetical ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        )
                        .overlay(
                            Capsule()
                                .stroke(sortOption != .alphabetical ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                    .foregroundColor(sortOption != .alphabetical ? .blue : .primary)
                    .confirmationDialog("Sort Trails", isPresented: $showSortMenu, titleVisibility: .visible) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            Button(option.rawValue) {
                                sortOption = option
                            }
                        }
                    }
                    
                    // Filter button
                    Button(action: {
                        showFilterSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .imageScale(.large)
                            Text("Filter")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(hasActiveFilters ? Color.blue.opacity(0.2) : Color(.systemGray6))
                        )
                        .overlay(
                            Capsule()
                                .stroke(hasActiveFilters ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                    .foregroundColor(hasActiveFilters ? .blue : .primary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Active filters summary (if any)
                if hasActiveFilters {
                    activeFiltersView
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                
                // Trails list
                trailsListView
            }
            .navigationTitle("Trails")
            .background(Color(.systemBackground))
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(
                    selectedDifficulty: $selectedDifficulty,
                    selectedDirection: $selectedDirection,
                    selectedStatus: $selectedStatus
                )
            }
        }
    }
    
    // Check if any filters are active
    private var hasActiveFilters: Bool {
        selectedDifficulty != nil || selectedDirection != nil || selectedStatus != nil
    }
    
    // View showing active filters with option to clear
    private var activeFiltersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear all button
                Button(action: {
                    selectedDifficulty = nil
                    selectedDirection = nil
                    selectedStatus = nil
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Clear All")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .foregroundColor(.primary)
                
                // Show difficulty filter if selected
                if let difficulty = selectedDifficulty {
                    HStack {
                        difficulty.displayIcon
                        Text(difficulty.rawValue)
                        Button(action: { selectedDifficulty = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Show direction filter if selected
                if let direction = selectedDirection {
                    HStack {
                        Image(systemName: direction.icon)
                        Text(direction.rawValue)
                        Button(action: { selectedDirection = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Show status filter if selected
                if let status = selectedStatus {
                    HStack {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.rawValue)
                        Button(action: { selectedStatus = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    // Trails list view
    private var trailsListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(filteredTrails) { trail in
                    TrailCard(
                        trail: trail,
                        currentStatus: trail.currentStatus(for: viewModel.parkStatus)
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 12)
        }
    }
    
    private var filteredTrails: [Trail] {
        var trails = Trail.allTrails
        
        // Apply search filter if needed
        if !searchText.isEmpty {
            trails = trails.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        
        // Apply difficulty filter if needed
        if let selectedDifficulty = selectedDifficulty {
            trails = trails.filter { $0.difficulty == selectedDifficulty }
        }
        
        // Apply direction filter if needed
        if let selectedDirection = selectedDirection {
            trails = trails.filter { $0.direction == selectedDirection }
        }
        
        // Apply status filter if needed
        if let selectedStatus = selectedStatus {
            trails = trails.filter { $0.currentStatus(for: viewModel.parkStatus) == selectedStatus }
        }
        
        // Apply sorting
        switch sortOption {
        case .alphabetical:
            return trails.sorted { $0.name < $1.name }
        case .status:
            return trails.sorted { $0.currentStatus(for: viewModel.parkStatus).rawValue < $1.currentStatus(for: viewModel.parkStatus).rawValue }
        case .direction:
            return trails.sorted { $0.direction.rawValue < $1.direction.rawValue }
        case .difficulty:
            return trails.sorted {
                let difficultyOrder: [TrailDifficulty] = [.green, .blue, .blackDiamond, .doubleBlackDiamond, .proline]
                let idx1 = difficultyOrder.firstIndex(of: $0.difficulty) ?? 0
                let idx2 = difficultyOrder.firstIndex(of: $1.difficulty) ?? 0
                return idx1 < idx2
            }
        }
    }
}

// Filter Sheet View
struct FilterSheetView: View {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedDifficulty: TrailDifficulty?
    @Binding var selectedDirection: TrailDirection?
    @Binding var selectedStatus: TrailStatus?
    
    var body: some View {
        NavigationView {
            Form {
                // Difficulty Section
                Section(header: Text("Difficulty")) {
                    ForEach(TrailDifficulty.allCases) { difficulty in
                        Button(action: {
                            if selectedDifficulty == difficulty {
                                selectedDifficulty = nil
                            } else {
                                selectedDifficulty = difficulty
                            }
                        }) {
                            HStack {
                                difficulty.displayIcon
                                Text(difficulty.rawValue)
                                Spacer()
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Direction Section
                Section(header: Text("Direction")) {
                    ForEach(TrailDirection.allCases) { direction in
                        Button(action: {
                            if selectedDirection == direction {
                                selectedDirection = nil
                            } else {
                                selectedDirection = direction
                            }
                        }) {
                            HStack {
                                Image(systemName: direction.icon)
                                Text(direction.rawValue)
                                Spacer()
                                if selectedDirection == direction {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Status Section
                Section(header: Text("Status")) {
                    Button(action: {
                        if selectedStatus == .open {
                            selectedStatus = nil
                        } else {
                            selectedStatus = .open
                        }
                    }) {
                        HStack {
                            Image(systemName: TrailStatus.open.icon)
                                .foregroundColor(TrailStatus.open.color)
                            Text("Open")
                            Spacer()
                            if selectedStatus == .open {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        if selectedStatus == .closed {
                            selectedStatus = nil
                        } else {
                            selectedStatus = .closed
                        }
                    }) {
                        HStack {
                            Image(systemName: TrailStatus.closed.icon)
                                .foregroundColor(TrailStatus.closed.color)
                            Text("Closed")
                            Spacer()
                            if selectedStatus == .closed {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Reset All Section
                Section {
                    Button(action: {
                        selectedDifficulty = nil
                        selectedDirection = nil
                        selectedStatus = nil
                    }) {
                        HStack {
                            Spacer()
                            Text("Reset All Filters")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Filter Trails")
            .navigationBarItems(
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: {
                    self.text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct TrailCard: View {
    let trail: Trail
    let currentStatus: TrailStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Trail image - full width
            Image(trail.imageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 150)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            // Top row with title and icons
            HStack(alignment: .center) {
                // Title
                Text(trail.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Difficulty icon (no text)
                trail.difficulty.displayIcon
                    .imageScale(.large)
                
                // Direction icon (no text)
                Image(systemName: trail.direction.icon)
                    .imageScale(.large)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)
            
            // Status row (separate line)
            HStack(spacing: 6) {
                Image(systemName: currentStatus.icon)
                    .foregroundColor(currentStatus.color)
                Text(currentStatus.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentStatus.color)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding(.bottom, 12)
        .background(Color.white)
    }
}

#Preview {
    TrailsView(viewModel: ParkStatusViewModel())
}
