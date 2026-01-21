//
//  RandomRecord.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  RandomRecord represents a single data record with a random numeric value.
//  Used throughout the app for data generation, storage, and synchronization.

import Foundation

// MARK: - RandomRecord
/// Domain model representing a random data record
/// 
/// Properties:
/// - id: Unique identifier for the record
/// - userId: ID of the user who owns this record
/// - value: Random integer value (typically 0-100)
/// - timestamp: When the record was created
/// - aiResponse: Optional AI-generated text response
/// - isSynced: Whether the record has been synced to remote storage
/// 
/// Conforms to:
/// - Codable: For JSON serialization/deserialization
/// - Identifiable: For SwiftUI list rendering
struct RandomRecord: Codable, Identifiable {
    let id: String
    let userId: String
    let value: Int
    let timestamp: Date
    var aiResponse: String?
    var isSynced: Bool
    
    // MARK: - Initializers
    
    /// Convenience initializer for creating new records
    /// 
    /// Automatically generates a UUID for the record ID and sets the current timestamp.
    /// Note: The `id` parameter is actually used as the `userId`.
    /// 
    /// - Parameters:
    ///   - id: User ID (will be assigned to userId, new UUID generated for record id)
    ///   - value: Random numeric value
    ///   - aiResponse: Optional AI-generated response (default: nil)
    ///   - isSynced: Sync status flag (default: false)
    init(id: String, value: Int, aiResponse: String? = nil, isSynced: Bool = false) {
        self.id = UUID().uuidString  // Generate new UUID for record
        self.userId = id              // Use provided id as userId
        self.value = value
        self.timestamp = Date()       // Set current timestamp
        self.aiResponse = aiResponse
        self.isSynced = isSynced
    }
    
    /// Initializer for loading records from database
    /// 
    /// Used when reconstructing records from database rows.
    /// All parameters are provided explicitly.
    /// 
    /// - Parameters:
    ///   - id: Record ID from database
    ///   - userId: User ID from database
    ///   - value: Numeric value from database
    ///   - timestamp: Creation timestamp from database
    ///   - aiResponse: Optional AI response from database
    ///   - isSynced: Sync status from database
    init(id: String, userId: String, value: Int, timestamp: Date, aiResponse: String?, isSynced: Bool) {
        self.id = id
        self.userId = userId
        self.value = value
        self.timestamp = timestamp
        self.aiResponse = aiResponse
        self.isSynced = isSynced
    }
}
