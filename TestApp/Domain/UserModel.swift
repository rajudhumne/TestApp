//
//  UserModel.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  User represents a user account in the system.
//  Used for authentication and user management.

import Foundation

// MARK: - User
/// Domain model representing a user account
/// 
/// Properties:
/// - id: Unique identifier (UUID string)
/// - username: User's login username (must be unique)
/// - passwordHash: Hashed password (should never be stored in plaintext)
/// - createdAt: Account creation timestamp
/// 
/// Conforms to:
/// - Codable: For JSON serialization/deserialization
/// - Identifiable: For SwiftUI list rendering and identification
/// 
/// Security Note:
/// The passwordHash should be generated using a secure hashing algorithm
/// (e.g., bcrypt, Argon2) before storing. Never store plaintext passwords.
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let passwordHash: String
    let createdAt: Date
}
