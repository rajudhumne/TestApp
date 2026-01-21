//
//  DatabaseService.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  LocalDatabaseService manages the SQLite database connection.
//  Provides a singleton instance for database access throughout the app.

import Foundation
import SQLite

// MARK: - DatabaseRepository Protocol
/// Protocol that all database repositories must conform to
/// Ensures consistent initialization and table creation across repositories
protocol DatabaseRepository {
    var db: Connection { get }
    init(db: Connection)
    func createTable() throws
}

// MARK: - DatabaseError
/// Errors that can occur during database operations
enum DatabaseError: Error {
    case connectionFailed          // Failed to establish database connection
    case connectionNotInitialized // Database connection not properly initialized
    case entryNotFound            // Requested database entry was not found
    case unknown(Error)           // Wraps unexpected errors from SQLite operations
}

// MARK: - LocalDatabaseService
/// Singleton service that manages the SQLite database connection
/// 
/// Responsibilities:
/// - Establishes and maintains database connection
/// - Provides connection access to repositories
/// - Stores database in app's Documents directory
final class LocalDatabaseService {
    
    // MARK: - Singleton
    
    /// Shared singleton instance of the database service
    /// Initialized on first access, fails fatally if connection cannot be established
    static let shared: LocalDatabaseService = {
        do {
            return try LocalDatabaseService()
        } catch {
            fatalError("Database startup failed: \(error)")
        }
    }()
    
    // MARK: - Properties
    
    /// The SQLite database connection
    private let db: Connection
    
    /// Name of the SQLite database file
    private let databaseName = "db.sqlite3"
    
    // MARK: - Initialization
    
    /// Initializes the database service and establishes SQLite connection
    /// 
    /// Database is stored in the app's Documents directory:
    /// `~/Documents/db.sqlite3`
    /// 
    /// - Throws: Error if database connection cannot be established
    init() throws {
        // Get the app's Documents directory
        let documentsURL = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        // Construct full path to database file
        let fileURL = documentsURL.appendingPathComponent(databaseName)
        
        // Attempt to create the SQLite connection
        self.db = try Connection(fileURL.path)
        
        print("Database connection established at \(String(describing: fileURL.path))")
    }
    
    // MARK: - Public Methods
    
    /// Returns the database connection for use by repositories
    /// - Returns: The SQLite Connection instance
    func getDBConnection() -> Connection {
        return db
    }
}

