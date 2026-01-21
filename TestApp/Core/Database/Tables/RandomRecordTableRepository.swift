//
//  RandomRecordTableRepository.swift
//  TestApp
//
//  Created by Raju Dhumne on 17/01/26.
//
//  RecordRepository handles all database operations for RandomRecord entities.
//  Provides CRUD operations and sync status management.

import Foundation
import SQLite

// MARK: - RecordRepository
/// Repository for managing RandomRecord database operations
/// 
/// Responsibilities:
/// - Creating and managing the number_records table
/// - Inserting new records
/// - Fetching unsynced records for synchronization
/// - Updating sync status
/// 
/// Conforms to Sendable for safe concurrent access.
final class RecordRepository: DatabaseRepository, Sendable {
    
    // MARK: - Properties
    
    /// SQLite database connection
    let db: Connection
    
    /// Reference to the number_records table
    private let table = Table("number_records")
    
    /// Reference to the users table (needed for foreign key constraint)
    private let usersTable = Table("users")
    
    // MARK: - Table Schema
    
    /// Column definitions for the number_records table
    struct Columns {
        static let id = Expression<String>("id")                    // Primary key
        static let userId = Expression<String>("user_id")            // Foreign key to users table
        static let value = Expression<Int>("value")                 // Random numeric value
        static let timestamp = Expression<Date>("timestamp")         // Record creation time
        static let isSynced = Expression<Bool>("is_synced")          // Sync status flag
        static let aiResponse = Expression<String?>("ai_response")  // Optional AI-generated response
    }

    // MARK: - Initialization
    
    /// Initializes the repository with a database connection
    /// Automatically creates the table if it doesn't exist
    /// 
    /// - Parameter db: SQLite database connection
    required init(db: Connection) {
        self.db = db
        // Silently create table if it doesn't exist
        do { try self.createTable()} catch {} 
    }

    // MARK: - Table Creation
    
    /// Creates the number_records table with schema and constraints
    /// 
    /// Table structure:
    /// - id: Primary key (String)
    /// - user_id: Foreign key to users table (cascade delete)
    /// - value: Integer value
    /// - timestamp: Date of record creation
    /// - is_synced: Boolean flag (defaults to false)
    /// - ai_response: Optional string for AI-generated content
    /// 
    /// - Throws: SQLite errors if table creation fails
    func createTable() throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.userId)
            t.column(Columns.value)
            t.column(Columns.timestamp)
            t.column(Columns.isSynced, defaultValue: false)
            t.column(Columns.aiResponse)
            t.foreignKey(Columns.userId, references: usersTable, Expression<String>("id"), delete: .cascade)
        })
    }

    // MARK: - CRUD Operations

    /// Inserts a new RandomRecord into the database
    /// 
    /// - Parameter record: The RandomRecord to insert
    /// - Throws: DatabaseError if insertion fails
    func insertRecord(_ record: RandomRecord) async throws {
        let insert = table.insert(
            Columns.id <- record.id,
            Columns.userId <- record.userId,
            Columns.value <- record.value,
            Columns.timestamp <- record.timestamp,
            Columns.isSynced <- record.isSynced,
            Columns.aiResponse <- record.aiResponse
        )
        try db.run(insert)
    }

    /// Fetches all records that haven't been synced to remote storage
    /// 
    /// Used by SyncService to determine which records need to be uploaded.
    /// 
    /// - Returns: Array of unsynced RandomRecord instances
    /// - Throws: DatabaseError if query fails
    func fetchUnsyncedRecords() async throws -> [RandomRecord] {
        // Filter for records where is_synced is false
        let query = table.filter(Columns.isSynced == false)
        
        // Using 'prepare' to fetch multiple rows efficiently
        let rows = try db.prepare(query)
        
        // Map database rows to RandomRecord domain models
        return rows.map { row in
            RandomRecord(
                id: row[Columns.id],
                userId: row[Columns.userId],
                value: row[Columns.value],
                timestamp: row[Columns.timestamp],
                aiResponse: row[Columns.aiResponse],
                isSynced: row[Columns.isSynced]
            )
        }
    }
    
    /// Marks multiple records as synced by their IDs
    /// 
    /// Updates the is_synced flag to true for all records with matching IDs.
    /// Used after successful remote synchronization.
    /// 
    /// - Parameter ids: Array of record IDs to mark as synced
    /// - Throws: DatabaseError if update fails
    func markAsSynced(ids: [String]) async throws {
        guard !ids.isEmpty else { return }
        
        // Filter records by matching IDs
        let targetRecords = table.filter(ids.contains(Columns.id))
        
        // Update is_synced flag to true
        try db.run(targetRecords.update(Columns.isSynced <- true))
    }
}
