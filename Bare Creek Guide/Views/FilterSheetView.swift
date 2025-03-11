//
//  FilterSheetView.swift
//  Bare Creek Guide
//
//  Created on 11/3/2025.
//

import SwiftUI

struct FilterSheetView: View {
    @ObservedObject var viewModel: TrailsViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // Favorites Section
                Section(header: Text("Favorites")) {
                    Toggle("Show Favorites Only", isOn: $viewModel.showFavoritesOnly)
                }
                
                // Difficulty Section
                Section(header: Text("Difficulty")) {
                    ForEach(TrailDifficulty.allCases) { difficulty in
                        Button(action: {
                            if viewModel.selectedDifficulty == difficulty {
                                viewModel.selectedDifficulty = nil
                            } else {
                                viewModel.selectedDifficulty = difficulty
                            }
                        }) {
                            HStack {
                                difficulty.displayIcon
                                Text(difficulty.rawValue)
                                Spacer()
                                if viewModel.selectedDifficulty == difficulty {
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
                            if viewModel.selectedDirection == direction {
                                viewModel.selectedDirection = nil
                            } else {
                                viewModel.selectedDirection = direction
                            }
                        }) {
                            HStack {
                                Image(systemName: direction.icon)
                                Text(direction.rawValue)
                                Spacer()
                                if viewModel.selectedDirection == direction {
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
                        if viewModel.selectedStatus == .open {
                            viewModel.selectedStatus = nil
                        } else {
                            viewModel.selectedStatus = .open
                        }
                    }) {
                        HStack {
                            Image(systemName: TrailStatus.open.icon)
                                .foregroundColor(TrailStatus.open.color)
                            Text("Open")
                            Spacer()
                            if viewModel.selectedStatus == .open {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                    
                    Button(action: {
                        if viewModel.selectedStatus == .closed {
                            viewModel.selectedStatus = nil
                        } else {
                            viewModel.selectedStatus = .closed
                        }
                    }) {
                        HStack {
                            Image(systemName: TrailStatus.closed.icon)
                                .foregroundColor(TrailStatus.closed.color)
                            Text("Closed")
                            Spacer()
                            if viewModel.selectedStatus == .closed {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                // Suitable Bikes Section
                Section(header: Text("Suitable Bikes")) {
                    ForEach(SuitableBike.allCases) { bike in
                        Button(action: {
                            if viewModel.selectedBike == bike {
                                viewModel.selectedBike = nil
                            } else {
                                viewModel.selectedBike = bike
                            }
                        }) {
                            HStack {
                                Image(systemName: "bicycle")
                                Text(bike.rawValue)
                                Spacer()
                                if viewModel.selectedBike == bike {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .foregroundColor(.primary)
                    }
                }
                
                // Reset All Section
                Section {
                    Button(action: {
                        viewModel.resetFilters()
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

#Preview {
    // Create a mock viewModel for preview
    let viewModel = TrailsViewModel(parkStatusViewModel: ParkStatusViewModel())
    return FilterSheetView(viewModel: viewModel)
}
