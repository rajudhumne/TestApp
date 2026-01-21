//
//  AppDelegate.swift
//  TestApp
//
//  Created by Raju Dhumne on 21/01/26.
//
//  AppDelegate handles app lifecycle events and Firebase integration.
//  Manages push notifications, FCM tokens, and notification permissions.

import AppKit
import Firebase
import FirebaseMessaging
import UserNotifications

// MARK: - AppDelegate
/// Application delegate handling system events and Firebase integration
/// 
/// Responsibilities:
/// - Initializing Firebase on app launch
/// - Managing push notification permissions and registration
/// - Handling FCM token registration
/// - Processing incoming notifications (foreground and background)
/// 
/// Conforms to:
/// - NSApplicationDelegate: macOS app lifecycle
/// - UNUserNotificationCenterDelegate: Notification handling
/// - MessagingDelegate: Firebase Cloud Messaging callbacks
class AppDelegate: NSObject,
                   NSApplicationDelegate,
                   UNUserNotificationCenterDelegate,
                   MessagingDelegate {
    
    // MARK: - NSApplicationDelegate
    
    /// Called when the application finishes launching
    /// 
    /// Sets up:
    /// 1. Firebase configuration
    /// 2. Notification center delegates
    /// 3. Notification permissions
    /// 4. Remote notification registration
    /// 
    /// - Parameter notification: Launch notification
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize Firebase SDK
        FirebaseApp.configure()
        
        // Set delegates for notification handling
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permissions from user
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Notification permission error:", error)
            } else {
                print("🔔 Notifications permission:", granted)
            }
        }
        
        // Register for remote notifications (push notifications)
        NSApplication.shared.registerForRemoteNotifications()
    }
    
    // MARK: - MessagingDelegate
    
    /// Called when Firebase Cloud Messaging registration token is received
    /// 
    /// The FCM token is used to send push notifications to this device.
    /// In production, this token should be sent to your backend server.
    /// 
    /// - Parameters:
    ///   - messaging: Firebase Messaging instance
    ///   - fcmToken: Firebase Cloud Messaging registration token
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("🖥️ macOS FCM Token:", fcmToken ?? "")
        // TODO: Send FCM token to backend server for push notification targeting
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Called when a notification arrives while app is in foreground
    /// 
    /// Determines how the notification should be presented to the user.
    /// 
    /// - Parameters:
    ///   - center: Notification center instance
    ///   - notification: The incoming notification
    /// - Returns: Presentation options (banner and sound)
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show banner and play sound even when app is in foreground
        return [.banner, .sound]
    }
    
    /// Called when user taps on a notification
    /// 
    /// Extracts notification data and posts a custom notification
    /// that can be observed by other parts of the app.
    /// 
    /// - Parameters:
    ///   - center: Notification center instance
    ///   - response: User's response to the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        // Extract user info from notification payload
        let userInfo = response.notification.request.content.userInfo
        print("🔔 Notification tapped:", userInfo)
        
        // Post custom notification for app to handle
        // Other parts of the app can observe .didReceiveCloudUpdate
        NotificationCenter.default.post(
            name: .didReceiveCloudUpdate,
            object: nil,
            userInfo: userInfo
        )
    }
}

// MARK: - Notification.Name Extension
/// Custom notification names used throughout the app
extension Notification.Name {
    /// Posted when a cloud update notification is received
    static let didReceiveCloudUpdate = Notification.Name("didReceiveCloudUpdate")
    
    /// Posted when a sync operation completes
    static let syncCompleted = Notification.Name("syncCompleted")
}
