//
//  AppView.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  AppView is the root view that manages navigation between login and dashboard.
//  Uses SessionManager to determine which view to display.

import SwiftUI

// MARK: - AppView
/// Root view that conditionally displays LoginView or DashboardView
/// 
/// Responsibilities:
/// - Observing session state from SessionManager
/// - Displaying LoginView when user is not logged in
/// - Displaying DashboardView when user is logged in
/// - Handling logout action from dashboard
struct AppView: View {
    
    // MARK: - Properties
    
    /// Session manager injected via environment
    /// Provides current authentication state
    @Environment(SessionManager.self) private var session
    
    // MARK: - Body
    
    var body: some View {
        Group {
            // Conditional rendering based on authentication state
            if let userId = session.currentUserId {
                // User is logged in - show dashboard
                DashboardView(userId: userId) {
                    // Logout callback
                    session.logout()
                }
            } else {
                // User is not logged in - show login screen
                LoginView { userId in
                    // Login callback - update session
                    session.login(userId: userId)
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    AppView()
}
