//
//  DataGeneratorService.swift
//  TestApp
//
//  Created by Raju Dhumne on 16/01/26.
//
//  DataGeneratorService generates random data records at regular intervals.
//  Uses AsyncStream to provide a reactive data stream to consumers.

import Foundation

// MARK: - DataGeneratorServiceProtocol
/// Protocol defining the data generation service interface
/// Enables dependency injection and testing
protocol DataGeneratorServiceProtocol {
    /// Starts generating records for the specified user
    func start(forUserId userId: String)
    
    /// Stops record generation and closes the stream
    func stop()
    
    /// Returns an AsyncStream that yields generated records
    func records() -> AsyncStream<RandomRecord>
}

// MARK: - DataGeneratorService
/// Service that generates random data records at 1-second intervals
/// 
/// Features:
/// - AsyncStream-based reactive data flow
/// - Background task execution
/// - Automatic cleanup on stop
final class DataGeneratorService: DataGeneratorServiceProtocol {
    
    // MARK: - Properties
    
    /// Background task that generates records
    private var task: Task<Void, Never>?
    
    /// Flag indicating if the service is currently running
    private var isRunning = false
    
    /// ID of the user for whom records are being generated
    private var currentUserId: String?
    
    /// Continuation for the AsyncStream, used to yield new records
    private var continuation: AsyncStream<RandomRecord>.Continuation?
    
    // MARK: - Public Methods
    
    /// Returns an AsyncStream that yields generated RandomRecord instances
    /// 
    /// The stream is created lazily and will start yielding records
    /// once `start(forUserId:)` is called.
    /// 
    /// - Returns: AsyncStream<RandomRecord> that yields records every second
    func records() -> AsyncStream<RandomRecord> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    /// Starts generating records for the specified user
    /// 
    /// Creates a background task that generates a new record every second.
    /// If already running, this method does nothing.
    /// 
    /// - Parameter userId: The user ID to associate with generated records
    func start(forUserId userId: String) {
        guard !isRunning else { return }
        
        isRunning = true
        currentUserId = userId
        
        // Create background task that generates records every second
        task = Task { [weak self] in
            while !Task.isCancelled {
                // Sleep for 1 second (1,000,000,000 nanoseconds)
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await self?.tick()
            }
        }
    }
    
    /// Stops record generation and closes the stream
    /// 
    /// Cancels the background task and finishes the AsyncStream,
    /// allowing consumers to complete their iteration.
    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        
        // Close the stream
        continuation?.finish()
        continuation = nil
    }
    
    // MARK: - Private Methods
    
    /// Generates a single random record and yields it to the stream
    /// 
    /// Creates a RandomRecord with:
    /// - A random value between 0 and 100
    /// - The current user ID
    /// - Current timestamp
    private func tick() async {
        guard let userId = currentUserId else { return }
        
        // Generate random record with value between 0-100
        let record = RandomRecord(id: userId, value: Int.random(in: 0...100))
        
        // Yield the record to stream consumers
        continuation?.yield(record)
    }
}
