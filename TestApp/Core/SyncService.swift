//
//  SyncService.swift
//  TestApp
//
//  Created by Raju Dhumne on 20/01/26.
//
//  SyncService handles periodic synchronization of local records to remote storage.
//  Runs in the background and syncs unsynced records at configured intervals.

import Foundation

// MARK: - SyncService
/// Service that periodically syncs local database records to remote storage
/// 
/// Features:
/// - Background task execution
/// - Configurable sync interval
/// - Automatic retry on failure
/// - Notification posting on sync completion
final class SyncService {
    
    // MARK: - Properties
    
    /// Repository for accessing record data
    let recordsRepository: RecordRepository
    
    /// Time interval between sync attempts (in seconds)
    /// Default: 100 seconds
    let syncInterval: TimeInterval
    
    /// Background task handling the sync loop
    private var task: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Initializes the sync service
    /// - Parameters:
    ///   - recordsRepository: Repository for accessing records
    ///   - syncInterval: Time between sync attempts in seconds (default: 100)
    init(recordsRepository: RecordRepository,
         syncInterval: TimeInterval = 100) {
        self.recordsRepository = recordsRepository
        self.syncInterval = syncInterval
    }
    
    // MARK: - Public Methods
    
    /// Starts the background sync loop
    /// 
    /// Creates a detached task that runs independently of the main actor.
    /// If already running, this method does nothing.
    func startSyncing() {
        guard task == nil else { return }
        
        // Create detached task to run sync loop in background
        task = Task.detached { [weak self] in
            await self?.syncLoop()
        }
    }
    
    /// Stops the sync service and cancels the background task
    func stop() {
        task?.cancel()
        task = nil
    }
    
    // MARK: - Private Methods
    
    /// Main sync loop that runs continuously until cancelled
    /// 
    /// Performs sync operation, then sleeps for the configured interval.
    /// Continues until the task is cancelled.
    private func syncLoop() async {
        while !Task.isCancelled {
            do {
                try await performSync()
            } catch {
                print("⚠️ Sync failed: \(error)")
            }
            
            // Sleep for the configured interval before next sync
            do {
                try await Task.sleep(nanoseconds: UInt64(syncInterval * 1_000_000_000))
            } catch {
                // Break if sleep was cancelled
                break
            }
        }
    }
    
    /// Performs a single sync operation
    /// 
    /// Process:
    /// 1. Fetches all unsynced records from database
    /// 2. Attempts to upload each record (currently stubbed)
    /// 3. Marks successfully synced records as synced
    /// 4. Posts notification when sync completes
    /// 
    /// - Throws: Database errors if fetch or update operations fail
    private func performSync() async throws {
        // Fetch all records that haven't been synced yet
        let unsynced = try await recordsRepository.fetchUnsyncedRecords()
        guard !unsynced.isEmpty else { return }
        
        // Process each unsynced record
        for record in unsynced {
            do {
                // TODO: Currently just logging the records.
                // If we need this feature, we need to purchase the plan for mobile backend code "functions"
                // In production, this would upload the record to a remote server
                // print(record)
            } catch {
                print("⚠️ Failed to upload record \(record.id): \(error)")
                continue
            }
        }
        
        // Mark all processed records as synced
        try await recordsRepository.markAsSynced(ids: unsynced.map { $0.id })
        print("✅ Synced \(unsynced.count) records")
        
        // Notify observers that sync completed
        NotificationCenter.default.post(name: .syncCompleted, object: nil)
    }
}
