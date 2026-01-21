//
//  DashboardViewModel.swift
//  TestApp
//
//  Created by Raju Dhumne on 17/01/26.
//
//  DashboardViewModel manages the dashboard's business logic and state.
//  Coordinates data generation, storage, synchronization, and AI processing.

import Foundation
import Observation

// MARK: - DashboardViewModel
/// View model for the Dashboard screen
/// 
/// Responsibilities:
/// - Managing data stream consumption
/// - Persisting records to database
/// - Triggering periodic AI analysis
/// - Coordinating background sync service
/// 
/// Uses @Observable for automatic SwiftUI view updates.
/// Runs on @MainActor to ensure UI updates happen on the main thread.
@Observable
@MainActor
final class DashboardViewModel {

    // MARK: - Published Properties
    
    /// List of recently generated records displayed in the UI
    var recentRecords: [RandomRecord] = []
    
    /// Latest AI-generated response text
    var latestAIResponse: String = "Waiting for minute mark..."
    
    /// Flag indicating if sync operation is in progress
    var isSyncing: Bool = false
    
    /// Flag for showing push notification indicator
    var showPushNotification: Bool = false

    // MARK: - Private Properties
    
    /// Counter tracking seconds elapsed (resets every 60 seconds)
    private var secondsCounter = 0
    
    /// ID of the current logged-in user
    private let userId: String
    
    /// Background task consuming the data stream
    private var streamTask: Task<Void, Never>?

    // MARK: - Dependencies
    
    /// Service for generating random data records
    let dataGeneratorService: DataGeneratorServiceProtocol
    
    /// Client for AI text generation
    let llmClient: LLMClient
    
    /// Repository for database operations
    let recordsDbService: RecordRepository
    
    /// Service for syncing records to remote storage
    let remoteRecordSync: SyncService

    // MARK: - Initialization
    
    /// Initializes the view model with required dependencies
    /// 
    /// - Parameters:
    ///   - userId: ID of the logged-in user
    ///   - dataGeneratorService: Service for generating data records
    ///   - llmClient: Client for AI generation
    ///   - recordsDbService: Repository for database operations
    ///   - remoteRecordSync: Service for remote synchronization
    init(userId: String,
         dataGeneratorService: DataGeneratorServiceProtocol,
         llmClient: LLMClient,
         recordsDbService: RecordRepository,
         remoteRecordSync: SyncService) {
        self.userId = userId
        self.dataGeneratorService = dataGeneratorService
        self.llmClient = llmClient
        self.recordsDbService = recordsDbService
        self.remoteRecordSync = remoteRecordSync
    }

    // MARK: - Public API

    /// Starts data generation, stream consumption, and sync service
    /// 
    /// This method:
    /// 1. Starts the data generator service
    /// 2. Begins consuming records from the stream
    /// 3. Starts the background sync service
    /// 
    /// Safe to call multiple times (guarded by streamTask check).
    func start() {
        guard streamTask == nil else { return }
        
        // Start generating records for this user
        dataGeneratorService.start(forUserId: userId)
        
        // Start consuming the stream in background
        streamTask = Task { await consumeStream() }
        
        // Start background sync service
        remoteRecordSync.startSyncing()
    }

    /// Stops all background operations
    /// 
    /// Cancels the stream task, stops data generation, and stops sync service.
    func stop() {
        streamTask?.cancel()
        streamTask = nil
        dataGeneratorService.stop()
        remoteRecordSync.stop()
    }

    // MARK: - Private Methods

    /// Consumes records from the data generator stream
    /// 
    /// Iterates through the AsyncStream and handles each record as it arrives.
    /// Continues until the stream is finished or task is cancelled.
    private func consumeStream() async {
        for await record in dataGeneratorService.records() {
            await handle(record)
        }
    }

    /// Handles a newly generated record
    /// 
    /// Process:
    /// 1. Adds record to recentRecords array (triggers UI update)
    /// 2. Persists record to database
    /// 3. Updates tick counter for AI generation
    /// 
    /// - Parameter record: The RandomRecord to process
    private func handle(_ record: RandomRecord) async {
        // Add to UI-visible list (triggers SwiftUI update)
        recentRecords.append(record)

        // Persist to database
        do {
            try await recordsDbService.insertRecord(record)
        } catch {
            print("DB insert failed:", error)
        }

        // Check if we should trigger AI generation
        await tick()
    }

    /// Tracks time elapsed and triggers AI generation every 60 seconds
    /// 
    /// Increments counter and calls generateAIResponse() when 60 seconds
    /// have elapsed, then resets the counter.
    private func tick() async {
        secondsCounter += 1
        
        // Only generate AI response after 60 seconds
        guard secondsCounter > 60 else { return }

        // Reset counter and generate AI response
        secondsCounter = 0
        await generateAIResponse()
    }

    /// Generates an AI response using a random number prompt
    /// 
    /// Creates a prompt with a random number and requests AI generation.
    /// Updates latestAIResponse on success, or shows error message on failure.
    private func generateAIResponse() async {
        // Generate random number for prompt
        let val = Int.random(in: 0...100)
        let prompt = "The number is \(val). Write a funny status message (max 10 words)."

        do {
            // Request AI generation using tinyLlama model
            latestAIResponse = try await llmClient.generate(using: .tinyLlama, prompt: prompt)
        } catch {
            // Show error message if AI service is unavailable
            latestAIResponse = "AI unavailable 🤖"
        }
    }

    /// Returns the current user ID
    /// - Returns: User ID string
    func getUserId() -> String { userId }
}
