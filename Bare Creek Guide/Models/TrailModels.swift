//
//  TrailModels.swift
//  Bare Creek Guide
//
//  Created by Adam on 27/2/2025.
//  Updated for persistence on 3/3/2025
//

import SwiftUI

enum TrailDifficulty: String, CaseIterable, Identifiable {
    case green = "Green"
    case blue = "Blue"
    case blackDiamond = "Black Diamond"
    case doubleBlackDiamond = "Double Black Diamond"
    case proline = "Proline"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .green:
            return .green
        case .blue:
            return .blue
        case .blackDiamond:
            return .black
        case .doubleBlackDiamond:
            return .black
        case .proline:
            return .purple
        }
    }
    
    var icon: String {
        switch self {
        case .green:
            return "circle.fill"
        case .blue:
            return "square.fill"
        case .blackDiamond:
            return "diamond.fill"
        case .doubleBlackDiamond:
            return "diamond.fill"
        case .proline:
            return "hexagon.fill"
        }
    }
    
    var displayIcon: some View {
        Group {
            if self == .doubleBlackDiamond {
                HStack(spacing: -5) {
                    Image(systemName: "diamond.fill")
                    Image(systemName: "diamond.fill")
                }
                .foregroundColor(self.color)
            } else {
                Image(systemName: self.icon)
                    .foregroundColor(self.color)
            }
        }
    }
}

enum TrailDirection: String, CaseIterable, Identifiable {
    case downhill = "Downhill"
    case uphill = "Uphill"
    case multiDirection = "Multi-direction"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .downhill:
            return "arrow.down"
        case .uphill:
            return "arrow.up"
        case .multiDirection:
            return "arrow.up.arrow.down"
        }
    }
}

enum TrailStatus: String {
    case open = "Open"
    case openWithSafetyOfficer = "Open if Safety Officer onsite"
    case caution = "Caution"
    case closed = "Closed"
    
    var color: Color {
        switch self {
        case .open:
            return .green
        case .openWithSafetyOfficer:
            return .blue
        case .caution:
            return .orange
        case .closed:
            return .red
        }
    }
    
    var icon: String {
        switch self {
        case .open:
            return "checkmark.circle.fill"
        case .openWithSafetyOfficer:
            return "person.fill.checkmark"
        case .caution:
            return "exclamationmark.triangle.fill"
        case .closed:
            return "xmark.circle.fill"
        }
    }
}

enum SuitableBike: String, CaseIterable, Identifiable {
    case enduro = "Enduro"
    case trail = "Trail"
    case bmx = "BMX"
    case dirtJumper = "Dirt Jumper"
    
    var id: String { self.rawValue }
}

struct TrailDetail {
    var location: String
    var overview: String
    var suitableBikes: [SuitableBike]
    var localsTips: String
}

// We use a class for the trail manager to observe changes
class TrailManager: ObservableObject {
    static let shared = TrailManager()
    
    @Published var trails: [Trail]
    
    private init() {
        // Initialize with predefined trails
        trails = Trail.predefinedTrails
        
        // Apply saved favorites
        FavoritesStorageManager.shared.applyFavoritesToTrails(&trails)
    }
    
    // Toggle favorite status for a specific trail
    func toggleFavorite(for trailID: UUID) {
        if let index = trails.firstIndex(where: { $0.id == trailID }) {
            trails[index].isFavorite.toggle()
            
            // Persist the change
            let idString = trailID.uuidString
            FavoritesStorageManager.shared.toggleFavorite(trailID: idString)
        }
    }
    
    // Get a binding to a specific trail
    func binding(for trail: Trail) -> Binding<Trail> {
        Binding<Trail>(
            get: {
                // Find and return the current state of the trail
                guard let index = self.trails.firstIndex(where: { $0.id == trail.id }) else {
                    // Return the original trail if not found (shouldn't happen)
                    return trail
                }
                return self.trails[index]
            },
            set: { newTrail in
                // Find and update the trail
                if let index = self.trails.firstIndex(where: { $0.id == trail.id }) {
                    self.trails[index] = newTrail
                    
                    // If the favorite status changed, persist it
                    if self.trails[index].isFavorite != newTrail.isFavorite {
                        let idString = trail.id.uuidString
                        if newTrail.isFavorite {
                            FavoritesStorageManager.shared.addFavorite(trailID: idString)
                        } else {
                            FavoritesStorageManager.shared.removeFavorite(trailID: idString)
                        }
                    }
                }
            }
        )
    }
}

struct Trail: Identifiable {
    let id: UUID
    let name: String
    let difficulty: TrailDifficulty
    let direction: TrailDirection
    let imageName: String
    var statusMap: [ParkStatus: TrailStatus]
    var isFavorite: Bool = false
    var details: TrailDetail
    
    func currentStatus(for parkStatus: ParkStatus) -> TrailStatus {
        return statusMap[parkStatus] ?? .closed
    }
    
    static let predefinedTrails: [Trail] = [
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID(),
            name: "Pump Track",
            difficulty: .blue,
            direction: .multiDirection,
            imageName: "Trails-PumpTrack",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .open,
                .extremeWinds: .open,
                .wetConditions: .open
            ],
            details: TrailDetail(
                location: "Next to the carpark, it's the first feature you'll see when arriving.",
                overview: "A huge pump track with berms, gaps, jumps, and enough twists and turns to find your own unique flow every time.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "Great place to start and warm up if you've never been to the park before. The perfect option when the wind is too strong or the ground is too wet for other trails."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID(),
            name: "Falcon Oath",
            difficulty: .green,
            direction: .downhill,
            imageName: "Trails-FalconOath",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .open,
                .extremeWinds: .open,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "At the bottom of the car park",
                overview: "A nice little flow trail with a huge berm to warm you up as you make your way down to the jump lines.",
                suitableBikes: [.trail, .enduro],
                localsTips: "Take the scenic route down to the rest of the park to stretch out and warm up before hitting more technical features."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID(),
            name: "Mild",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-Mild",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Right hand side of the Trio Zone",
                overview: "A tabletop jump line that helps you build on your jumping skills. The first few jumps have rocks to clear, so jumping skills are required.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Carve the first few jumps to get an extra boost and look out for the Mild to Medium transfer jump option."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID(),
            name: "Medium",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-Medium",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Middle of the Trio Zone",
                overview: "A big jump line with a dirt whale tail, step up and drop to start you off. Great for building confidence with progressively bigger jumps.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Roll in from the top and don't worry about tapping your brakes - speed is your friend on this one!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000005") ?? UUID(),
            name: "Spicy",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Spicy",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .openWithSafetyOfficer,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Left hand side of the Trio Zone",
                overview: "Big dirt jumps with plenty of air time on offer. Starts with a decent 4m drop into one of the kickiest jumps in the park, then hits the long and low before a huge step up to finish the line.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Roll in from a standstill, and pump the last roller hard before the step up to get maximum air time."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000006") ?? UUID(),
            name: "Social Distancing",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-SocialDistancing",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "After Mild, Medium and Spicy merge",
                overview: "A short run that connects you from the Trio Zone to Livewire. Features a small double into a big step up that gives you enough air time for tricks.",
                suitableBikes: [.enduro, .trail],
                localsTips: "The step up is the best jump in the park to practice your whips, no-handers, and other aerial tricks."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000007") ?? UUID(),
            name: "Livewire",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Livewire",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .openWithSafetyOfficer,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "After the Trio Zone and Social Distancing, turn left into Livewire",
                overview: "A huge 6m drop called 'The Cliff', followed by a shark fin then into a massive step up called 'Zapper'. A fast line with lots of air time.",
                suitableBikes: [.enduro, .trail],
                localsTips: "However fast you think you're going... you can go faster. Commit to the speed!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000008") ?? UUID(),
            name: "Trash Panda",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-TrashPanda",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "In the middle of the park, after you pass the Trio Zone",
                overview: "A flowy trail full of berms and drops. Halfway down you can continue straight for more flowy berms or turn right to hit the drop section with three options, ranging from rollable to a big 4m drop.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Use the drop zone to build confidence and prepare for tackling the Cliff on Livewire."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000009") ?? UUID(),
            name: "Bin Chicken",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-BinChicken",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "In the middle of the park, on the side of the hill",
                overview: "The easiest jump line in the park. Features a mellow drop into several table top jumps, a huge berm, and finishes with a step down.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Great place to start and build up confidence. Once you can clear the Bin Chicken jumps, you're ready to progress to Mild!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000010") ?? UUID(),
            name: "Short Circuit",
            difficulty: .blue,
            direction: .downhill,
            imageName: "Trails-ShortCircuit",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "The right-hand line in the dirt jump section",
                overview: "A gapped jump line with steep take-offs and landings, finishing with a tight berm to exit the track.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "This line flows well into the next section and is a great introduction to the dirt jump zone."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000011") ?? UUID(),
            name: "Power Trip",
            difficulty: .blackDiamond,
            direction: .downhill,
            imageName: "Trails-PowerTrip",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Second line from the right in the dirt jump section",
                overview: "A gapped jump line with steep take-offs and landings, ending with either a tight berm to exit or a wooden kicker to continue into Blackout.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "This line flows extremely well. Roll in, pump hard, and don't touch the brakes for the best experience."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000012") ?? UUID(),
            name: "Darcside",
            difficulty: .proline,
            direction: .downhill,
            imageName: "Trails-Darcside",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Bottom of the park",
                overview: "Currently closed due to maintenance. Expected to open in the first half of 2025.",
                suitableBikes: [.enduro, .trail],
                localsTips: "Nothing yet - stay tuned for updates!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000013") ?? UUID(),
            name: "Blackout",
            difficulty: .doubleBlackDiamond,
            direction: .downhill,
            imageName: "Trails-Blackout",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Third line from the right in the dirt jump section",
                overview: "A dirt jump line with wooden kickers throughout the entire run.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "Make sure you boost hard to maintain momentum, otherwise you won't make it all the way through the line."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000014") ?? UUID(),
            name: "Watts Up",
            difficulty: .proline,
            direction: .downhill,
            imageName: "Trails-WattsUp",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .closed,
                .windyConditions: .closed,
                .strongWinds: .closed,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Left-hand side of the dirt jump section",
                overview: "Currently closed due to maintenance. No confirmed reopening date available at this time.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "Nothing yet - check back for updates!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000015") ?? UUID(),
            name: "Four Seconds",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-FourSeconds",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Next to the Trio Zone",
                overview: "An uphill trail that returns you from Social Distancing to the top of the Trio Zone.",
                suitableBikes: [.enduro, .trail],
                localsTips: "If you're pushing your bike uphill, stay to the side so eBikes can pass safely."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000016") ?? UUID(),
            name: "The Butler",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-TheButler",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "After Livewire and the middle section",
                overview: "An uphill trail that zigzags across the mountain to return you to the start after riding Livewire, Bin Chicken, and Trash Panda.",
                suitableBikes: [.enduro, .trail],
                localsTips: "It's much more enjoyable than pushing your bike up Lighten Up!"
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000017") ?? UUID(),
            name: "Lighten Up",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-LightenUp",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "At the bottom of the middle section and end of Livewire",
                overview: "A rocky uphill trail that eBikers can ride while others typically push their bikes up to return to the starting point.",
                suitableBikes: [.enduro, .trail],
                localsTips: "If you're pushing your bike uphill, stay to one side to make space for eBikes passing through."
            )
        ),
        Trail(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000018") ?? UUID(),
            name: "Power Back",
            difficulty: .green,
            direction: .uphill,
            imageName: "Trails-PowerBack",
            statusMap: [
                .closed: .closed,
                .perfectConditions: .open,
                .windyConditions: .open,
                .strongWinds: .caution,
                .extremeWinds: .closed,
                .wetConditions: .closed
            ],
            details: TrailDetail(
                location: "Entrance of the dirt jump section",
                overview: "A tight pump trail designed to help you gain enough momentum to return to the dirt jump launch pad without pedaling.",
                suitableBikes: [.bmx, .dirtJumper],
                localsTips: "Focus on your pumping technique and enjoy the flow - no pedaling required!"
            )
        )
    ]
}
