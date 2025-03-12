//
//  TrailListView.swift
//  Bare Creek Guide
//
//  Created on 11/3/2025.
//  Improved state sharing on 11/3/2025.
//  Updated preview syntax on 12/3/2025.
//

import SwiftUI

struct TrailListView: View {
    @ObservedObject var viewModel: TrailsViewModel
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(viewModel.filteredTrails) { trail in
                    NavigationLink(destination: TrailDetailView(
                        trail: viewModel.trailManager.binding(for: trail),
                        parkStatus: viewModel.parkStatus
                    )) {
                        TrailCard(
                            trail: trail,
                            currentStatus: trail.currentStatus(for: viewModel.parkStatus),
                            isFavorite: trail.isFavorite,
                            onFavoriteToggle: {
                                viewModel.trailManager.toggleFavorite(for: trail.id)
                            }
                        )
                        .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 12)
        }
    }
}

struct TrailCard: View {
    let trail: Trail
    let currentStatus: TrailStatus
    let isFavorite: Bool
    let onFavoriteToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Trail image - full width
            ZStack(alignment: .topTrailing) {
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
                
                // Favorite button
                Button(action: {
                    onFavoriteToggle()
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .white)
                        .padding(10)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(12)
            }
            
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
            
            // Preview of suitable bikes
            HStack {
                Image(systemName: "bicycle")
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
                
                Text(trail.details.suitableBikes.map { $0.rawValue }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 6)
        }
        .padding(.bottom, 12)
        .background(Color.white)
    }
}

// Preview wrapper to provide navigation context
struct TrailListPreviewWrapper: View {
    var body: some View {
        NavigationView {
            // Create a mock viewModel for preview
            TrailListView(viewModel: TrailsViewModel(parkStatusViewModel: ParkStatusViewModel()))
        }
    }
}

#Preview {
    TrailListPreviewWrapper()
}
