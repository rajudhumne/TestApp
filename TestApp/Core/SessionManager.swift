//
//  SessionManager.swift
//  TestApp
//
//  Created by Raju Dhumne on 21/01/26.
//
//  SessionManager manages user authentication state throughout the app.
//  Uses SwiftUI's @Observable macro for automatic view updates.

import SwiftUI

// MARK: - SessionManager
/// Manages user session and authentication state
/// 
/// Responsibilities:
/// - Tracks current logged-in user
/// - Provides login/logout functionality
/// - Automatically updates SwiftUI views when state changes
/// 
/// Uses SwiftUI's @Observable macro to enable reactive updates.
@Observable
final class SessionManager {
    
    // MARK: - Properties
    
    /// ID of the currently logged-in user
    /// `nil` indicates no user is logged in
    var currentUserId: String? = nil
    
    /// Computed property indicating if a user is currently logged in
    var isLoggedIn: Bool { currentUserId != nil }

    // MARK: - Public Methods
    
    /// Logs in a user by setting their ID
    /// 
    /// This will trigger SwiftUI view updates automatically
    /// due to the @Observable macro.
    /// 
    /// - Parameter userId: The unique identifier of the user to log in
    func login(userId: String) {
        currentUserId = userId
    }

    /// Logs out the current user by clearing the user ID
    /// 
    /// This will trigger SwiftUI view updates automatically
    /// due to the @Observable macro.
    func logout() {
        currentUserId = nil
    }
}
