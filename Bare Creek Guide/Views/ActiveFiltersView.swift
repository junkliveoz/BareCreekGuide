//
//  ActiveFiltersView.swift
//  Bare Creek Guide
//
//  Created on 11/3/2025.
//  Updated preview syntax on 12/3/2025.
//

import SwiftUI

struct ActiveFiltersView: View {
    @ObservedObject var viewModel: TrailsViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Clear all button
                Button(action: {
                    viewModel.resetFilters()
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
                
                // Show favorites filter if selected
                if viewModel.showFavoritesOnly {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                        Text("Favorites Only")
                        Button(action: { viewModel.showFavoritesOnly = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Show difficulty filter if selected
                if let difficulty = viewModel.selectedDifficulty {
                    HStack {
                        difficulty.displayIcon
                        Text(difficulty.rawValue)
                        Button(action: { viewModel.selectedDifficulty = nil }) {
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
                if let direction = viewModel.selectedDirection {
                    HStack {
                        Image(systemName: direction.icon)
                        Text(direction.rawValue)
                        Button(action: { viewModel.selectedDirection = nil }) {
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
                if let status = viewModel.selectedStatus {
                    HStack {
                        Image(systemName: status.icon)
                            .foregroundColor(status.color)
                        Text(status.rawValue)
                        Button(action: { viewModel.selectedStatus = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Show bike filter if selected
                if let bike = viewModel.selectedBike {
                    HStack {
                        Image(systemName: "bicycle")
                        Text(bike.rawValue)
                        Button(action: { viewModel.selectedBike = nil }) {
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
}

#Preview {
    // Create a mock viewModel with filters for preview
    let viewModel = TrailsViewModel(parkStatusViewModel: ParkStatusViewModel())
    viewModel.selectedDifficulty = .blue
    viewModel.showFavoritesOnly = true
    
    return VStack {
        ActiveFiltersView(viewModel: viewModel)
            .padding()
    }
}
