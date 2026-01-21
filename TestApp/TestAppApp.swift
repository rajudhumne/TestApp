//
//  TestAppApp.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  TestAppApp is the main entry point for the macOS application.
//  Sets up the app structure, session management, and Firebase integration.

import SwiftUI

// MARK: - TestAppApp
/// Main app structure and entry point
/// 
/// Responsibilities:
/// - Initializing the app with AppDelegate for Firebase
/// - Creating and providing SessionManager to the view hierarchy
/// - Setting up the main window structure
@main
struct TestAppApp: App {
    
    // MARK: - Properties
    
    /// App delegate for handling system events and Firebase initialization
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    /// Session manager instance shared throughout the app
    /// Manages user authentication state
    @State private var sessionManager = SessionManager()
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                // Root view with session manager injected via environment
                AppView()
                    .environment(sessionManager)
            }
        }
    }
}
