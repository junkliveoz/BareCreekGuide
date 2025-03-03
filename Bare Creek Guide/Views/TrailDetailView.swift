//
//  TrailDetailView.swift
//  Bare Creek Guide
//
//  Created on 3/3/2025.
//

import SwiftUI

struct TrailDetailView: View {
    @Binding var trail: Trail
    let parkStatus: ParkStatus
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Trail name header
                Text(trail.name)
                    .font(.system(size: 28, weight: .bold))
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Hero image with rounded corners and favorite button
                ZStack(alignment: .topTrailing) {
                    Image(trail.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Favorite button
                    Button(action: {
                        trail.isFavorite.toggle()
                        // Storage is handled by the binding from TrailManager
                    }) {
                        Image(systemName: trail.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(trail.isFavorite ? .red : .white)
                            .padding(10)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(12)
                }
                .padding(.horizontal)
                
                // Difficulty and Direction row
                HStack {
                    // Difficulty
                    HStack(spacing: 6) {
                        trail.difficulty.displayIcon
                            .imageScale(.medium)
                        
                        Text(trail.difficulty.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                    
                    // Direction
                    HStack(spacing: 6) {
                        Image(systemName: trail.direction.icon)
                        Text(trail.direction.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                
                // Status section
                HStack {
                    Image(systemName: trail.currentStatus(for: parkStatus).icon)
                        .foregroundColor(trail.currentStatus(for: parkStatus).color)
                        .font(.system(size: 20))
                    
                    Text("Current Status: \(trail.currentStatus(for: parkStatus).rawValue)")
                        .font(.headline)
                        .foregroundColor(trail.currentStatus(for: parkStatus).color)
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Location section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Location", icon: "mappin.and.ellipse")
                    
                    Text(trail.details.location)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Overview section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Overview", icon: "info.circle")
                    
                    Text(trail.details.overview)
                        .font(.body)
                }
                .padding(.horizontal)
                
                // Suitable bikes section
                VStack(alignment: .leading, spacing: 8) {
                    SectionHeaderView(title: "Suitable Bikes", icon: "bicycle")
                    
                    HStack(spacing: 10) {
                        ForEach(trail.details.suitableBikes, id: \.self) { bike in
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
                    
                    Text(trail.details.localsTips)
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
                .foregroundColor(.black)
            }
        )
    }
}

struct SectionHeaderView: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color("AccentColor"))
            
            Text(title)
                .font(.headline)
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
}
