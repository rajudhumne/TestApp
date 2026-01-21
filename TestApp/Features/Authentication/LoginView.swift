//
//  LoginView.swift
//  TestApp
//
//  Created by Raju Dhumne on 17/01/26.
//
//  LoginView provides user authentication and account creation.
//  Handles both login for existing users and registration for new users.

import SwiftUI

// MARK: - LoginView
/// SwiftUI view for user authentication
/// 
/// Features:
/// - Username and password input
/// - Automatic account creation if user doesn't exist
/// - Error message display
/// - Callback on successful login
struct LoginView: View {
    
    // MARK: - Properties
    
    /// Callback invoked when login/registration succeeds
    /// Parameter: User ID of the authenticated user
    var onLoginSuccess: (String) -> Void
    
    /// Username input field state
    @State private var username = ""
    
    /// Password input field state
    /// Note: In production, ensure password is hashed before storage
    @State private var password = ""
    
    /// Error message to display to user
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 20) {
            // App title
            Text("Founding Engineer Test")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Input fields
            VStack(alignment: .leading) {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .frame(width: 300)
            
            // Error message display
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).font(.caption)
            }
            
            // Login/Create Account button
            Button("Login / Create Account") {
                Task {
                    await handleLogin()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
    
    // MARK: - Private Methods
    
    /// Handles the login/registration process
    /// 
    /// Process:
    /// 1. Validates that username and password are not empty
    /// 2. Attempts to find existing user by username
    /// 3. If user exists: verifies password and logs in
    /// 4. If user doesn't exist: creates new account and logs in
    /// 
    /// Security Note:
    /// Currently compares plaintext password with stored hash.
    /// In production, this should use proper password hashing (bcrypt, Argon2).
    private func handleLogin() async {
        // Validate input
        guard !username.isEmpty, !password.isEmpty else { return }
        
        // Get database connection and user repository
        let dbConnection = LocalDatabaseService.shared.getDBConnection()
        let usersDb = UserRepository(db: dbConnection)
        
        do {
            // Try to find existing user
            if let existingUser = try await usersDb.getUser(name: username) {
                // User exists - verify password
                // TODO: Replace with proper password verification using hashing
                if existingUser.passwordHash == password {
                    onLoginSuccess(existingUser.id)
                } else {
                    errorMessage = "Invalid credentials"
                }
            } else {
                // User doesn't exist - create new account
                // TODO: Hash password before storing
                let newUser = try await usersDb.createUser(name: username, passHash: password)
                onLoginSuccess(newUser.id)
            }
        } catch {
            // Display database errors to user
            errorMessage = "Database Error: \(error.localizedDescription)"
        }
    }
}

#Preview {
    LoginView { userId in
        print(userId)
    }
}
