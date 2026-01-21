//
//  UserTableRepository.swift
//  TestApp
//
//  Created by Raju Dhumne on 17/01/26.
//
//  UserRepository handles all database operations for User entities.
//  Manages user authentication and account creation.

import Foundation
import SQLite

// MARK: - UserRepository
/// Repository for managing User database operations
/// 
/// Responsibilities:
/// - Creating and managing the users table
/// - Creating new user accounts
/// - Retrieving users by username for authentication
/// 
/// The table is public to allow RecordRepository to reference it for foreign key constraints.
/// Conforms to Sendable for safe concurrent access.
final class UserRepository: DatabaseRepository, Sendable {
    
    // MARK: - Properties
    
    /// SQLite database connection
    let db: Connection
    
    /// Reference to the users table
    /// Made public so RecordRepository can reference it for foreign key constraints
    let table = Table("users")
    
    // MARK: - Table Schema
    
    /// Column definitions for the users table
    struct Columns {
        static let id = Expression<String>("id")              // Primary key (UUID)
        static let username = Expression<String>("username")    // Unique username
        static let passwordHash = Expression<String>("password_hash")  // Hashed password
        static let createdAt = Expression<Date>("created_at")  // Account creation timestamp
    }

    // MARK: - Initialization
    
    /// Initializes the repository with a database connection
    /// Automatically creates the table if it doesn't exist
    /// 
    /// - Parameter db: SQLite database connection
    required init(db: Connection) {
        self.db = db
        // Silently create table if it doesn't exist
        do { try self.createTable() } catch {}
    }

    // MARK: - Table Creation
    
    /// Creates the users table with schema and constraints
    /// 
    /// Table structure:
    /// - id: Primary key (String UUID)
    /// - username: Unique username (enforced by unique constraint)
    /// - password_hash: Hashed password string
    /// - created_at: Account creation timestamp
    /// 
    /// - Throws: SQLite errors if table creation fails
    func createTable() throws {
        try db.run(table.create(ifNotExists: true) { t in
            t.column(Columns.id, primaryKey: true)
            t.column(Columns.username, unique: true)  // Enforce unique usernames
            t.column(Columns.passwordHash)
            t.column(Columns.createdAt)
        })
    }

    // MARK: - CRUD Operations

    /// Creates a new user account in the database
    /// 
    /// Generates a new UUID for the user and sets the creation timestamp.
    /// 
    /// - Parameters:
    ///   - name: Username for the new account
    ///   - passHash: Hashed password (should be hashed before calling this method)
    /// - Returns: The newly created User object
    /// - Throws: DatabaseError if insertion fails (e.g., duplicate username)
    func createUser(name: String, passHash: String) async throws -> User {
        // Create new user with generated UUID and current timestamp
        let newUser = User(
            id: UUID().uuidString,
            username: name,
            passwordHash: passHash,
            createdAt: Date()
        )
        
        // Insert into database
        let insert = table.insert(
            Columns.id <- newUser.id,
            Columns.username <- newUser.username,
            Columns.passwordHash <- newUser.passwordHash,
            Columns.createdAt <- newUser.createdAt
        )
        
        do {
            try db.run(insert)
            return newUser
        } catch {
            // Wrap SQLite errors in our error type
            throw DatabaseError.unknown(error)
        }
    }

    /// Retrieves a user by username
    /// 
    /// Used for authentication - looks up user by username to verify credentials.
    /// 
    /// - Parameter name: Username to search for
    /// - Returns: User object if found, nil otherwise
    /// - Throws: DatabaseError if query fails
    func getUser(name: String) async throws -> User? {
        // Filter by username (case-sensitive)
        let query = table.filter(Columns.username == name)
        
        do {
            // pluck returns the first matching row, or nil if none found
            guard let row = try db.pluck(query) else { return nil }
            
            // Map database row to User domain model
            return User(
                id: row[Columns.id],
                username: row[Columns.username],
                passwordHash: row[Columns.passwordHash],
                createdAt: row[Columns.createdAt]
            )
        } catch {
            // Wrap SQLite errors in our error type
            throw DatabaseError.unknown(error)
        }
    }
}
