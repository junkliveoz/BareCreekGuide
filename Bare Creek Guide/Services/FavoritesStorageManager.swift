//
//  FavoritesStorageManager.swift
//  Bare Creek Guide
//
//  Created on 3/3/2025.
//  Updated to disable CloudKit in development
//

import SwiftUI
import CloudKit

class FavoritesStorageManager: ObservableObject {
    // Flag to disable CloudKit during development/testing
    #if DEBUG
    private let useCloudKit = false
    #else
    private let useCloudKit = true
    #endif
    
    // Shared instance for app-wide access
    static let shared = FavoritesStorageManager()
    
    // Published property for SwiftUI to observe changes
    @Published var favoriteTrailIDs: Set<String> = []
    
    // Keys for storage
    private let userDefaultsKey = "favoriteTrailIDs"
    private let iCloudKey = "favoriteTrailIDs"
    
    // CloudKit container
    private let container = CKContainer.default()
    
    private init() {
        // Load favorites from local storage on initialization
        loadFavorites()
        
        // Set up iCloud notifications for changes
        if useCloudKit {
            setupiCloudNotifications()
        }
    }
    
    // MARK: - Public Methods
    
    /// Add a trail to favorites
    func addFavorite(trailID: String) {
        favoriteTrailIDs.insert(trailID)
        saveFavorites()
    }
    
    /// Remove a trail from favorites
    func removeFavorite(trailID: String) {
        favoriteTrailIDs.remove(trailID)
        saveFavorites()
    }
    
    /// Toggle a trail's favorite status
    func toggleFavorite(trailID: String) {
        if favoriteTrailIDs.contains(trailID) {
            favoriteTrailIDs.remove(trailID)
        } else {
            favoriteTrailIDs.insert(trailID)
        }
        saveFavorites()
    }
    
    /// Check if a trail is favorited
    func isFavorite(trailID: String) -> Bool {
        return favoriteTrailIDs.contains(trailID)
    }
    
    /// Apply stored favorites to trail array
    func applyFavoritesToTrails(_ trails: inout [Trail]) {
        for i in 0..<trails.count {
            trails[i].isFavorite = isFavorite(trailID: trails[i].id.uuidString)
        }
    }
    
    // MARK: - Private Methods
    
    /// Save favorites to UserDefaults and iCloud
    private func saveFavorites() {
        // Save to UserDefaults
        UserDefaults.standard.set(Array(favoriteTrailIDs), forKey: userDefaultsKey)
        
        // Save to iCloud only if enabled
        if useCloudKit {
            saveFavoritesToiCloud()
        }
    }
    
    /// Load favorites from UserDefaults
    private func loadFavorites() {
        // Load from UserDefaults
        if let storedFavorites = UserDefaults.standard.array(forKey: userDefaultsKey) as? [String] {
            favoriteTrailIDs = Set(storedFavorites)
        }
        
        // Attempt to merge with iCloud data only if enabled
        if useCloudKit {
            loadFavoritesFromiCloud()
        }
    }
    
    // MARK: - iCloud Integration
    
    /// Save favorites to iCloud Key-Value store
    private func saveFavoritesToiCloud() {
        // Skip if CloudKit is disabled
        guard useCloudKit else { return }
        
        // Convert to array for NSUbiquitousKeyValueStore
        NSUbiquitousKeyValueStore.default.set(Array(favoriteTrailIDs), forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
        
        // Also save to CloudKit for more robust sync
        saveToCloudKit()
    }
    
    /// Load favorites from iCloud Key-Value store
    private func loadFavoritesFromiCloud() {
        // Skip if CloudKit is disabled
        guard useCloudKit else { return }
        
        if let iCloudFavorites = NSUbiquitousKeyValueStore.default.array(forKey: iCloudKey) as? [String] {
            // Merge with local favorites
            let iCloudSet = Set(iCloudFavorites)
            favoriteTrailIDs = favoriteTrailIDs.union(iCloudSet)
            
            // Save merged set back to UserDefaults
            UserDefaults.standard.set(Array(favoriteTrailIDs), forKey: userDefaultsKey)
        }
        
        // Also try to load from CloudKit
        loadFromCloudKit()
    }
    
    /// Set up notifications for iCloud changes
    private func setupiCloudNotifications() {
        // Skip if CloudKit is disabled
        guard useCloudKit else { return }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChangeExternally),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        
        // Start observing changes
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    /// Handle external changes to iCloud Key-Value store
    @objc private func iCloudDidChangeExternally(notification: Notification) {
        // Skip if CloudKit is disabled
        guard useCloudKit else { return }
        
        guard let userInfo = notification.userInfo else { return }
        
        // Check if our key changed
        if let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
           changedKeys.contains(iCloudKey) {
            
            // Update our local copy
            if let iCloudFavorites = NSUbiquitousKeyValueStore.default.array(forKey: iCloudKey) as? [String] {
                // Use main thread for UI updates
                DispatchQueue.main.async {
                    let iCloudSet = Set(iCloudFavorites)
                    // Merge with local favorites
                    self.favoriteTrailIDs = self.favoriteTrailIDs.union(iCloudSet)
                    // Save merged set back to UserDefaults
                    UserDefaults.standard.set(Array(self.favoriteTrailIDs), forKey: self.userDefaultsKey)
                }
            }
        }
    }
    
    // MARK: - CloudKit Integration (more robust than Key-Value store)
    
    /// Save favorites to CloudKit
    private func saveToCloudKit() {
        // Skip if CloudKit is disabled
        guard useCloudKit else {
            print("CloudKit save operation skipped in development build")
            return
        }
        
        // Get the private database
        let privateDB = container.privateCloudDatabase
        
        // Create a record ID and record for our favorites
        let recordID = CKRecord.ID(recordName: "FavoriteTrails")
        let record = CKRecord(recordType: "UserFavorites", recordID: recordID)
        
        // Store favorites as a JSON string for simplicity
        let favoritesArray = Array(favoriteTrailIDs)
        if let favoritesData = try? JSONSerialization.data(withJSONObject: favoritesArray, options: []),
           let favoritesString = String(data: favoritesData, encoding: .utf8) {
            record["favorites"] = favoritesString
        }
        
        // Save the record to CloudKit
        privateDB.save(record) { (record, error) in
            if let error = error {
                print("Error saving favorites to CloudKit: \(error)")
            }
        }
    }
    
    /// Load favorites from CloudKit
    private func loadFromCloudKit() {
        // Skip if CloudKit is disabled
        guard useCloudKit else {
            print("CloudKit load operation skipped in development build")
            return
        }
        
        // Get the private database
        let privateDB = container.privateCloudDatabase
        
        // Create a record ID for our favorites
        let recordID = CKRecord.ID(recordName: "FavoriteTrails")
        
        // Fetch the record from CloudKit
        privateDB.fetch(withRecordID: recordID) { [weak self] (record, error) in
            guard let self = self else { return }
            
            if let error = error {
                // Record might not exist yet, which is fine
                print("CloudKit fetch error (may be normal for first use): \(error)")
                return
            }
            
            if let record = record,
               let favoritesString = record["favorites"] as? String,
               let favoritesData = favoritesString.data(using: .utf8),
               let favoritesArray = try? JSONSerialization.jsonObject(with: favoritesData, options: []) as? [String] {
                
                // Use main thread for UI updates
                DispatchQueue.main.async {
                    let cloudKitSet = Set(favoritesArray)
                    // Merge with local favorites
                    self.favoriteTrailIDs = self.favoriteTrailIDs.union(cloudKitSet)
                    // Save merged set back to UserDefaults
                    UserDefaults.standard.set(Array(self.favoriteTrailIDs), forKey: self.userDefaultsKey)
                    // Also update iCloud Key-Value store
                    NSUbiquitousKeyValueStore.default.set(Array(self.favoriteTrailIDs), forKey: self.iCloudKey)
                    NSUbiquitousKeyValueStore.default.synchronize()
                }
            }
        }
    }
}
