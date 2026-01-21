//
//  TestAppTests.swift
//  TestAppTests
//
//  Created by Raju Dhumne on 16/01/26.
//

import Foundation
import SQLite
import Testing
@testable import TestApp
@MainActor
struct TestAppTests {
    
    @Test("DataGenerator emits records and stops cleanly")
    func dataGeneratorLifecycle() async throws {
        let generator = DataGeneratorService()
        let stream = generator.records()
        
        generator.start(forUserId: "user-123")
        var iterator = stream.makeAsyncIterator()
        
        let first = await iterator.next()
        #expect(first?.userId == "user-123")
        
        generator.stop()
        let afterStop = await iterator.next()
        #expect(afterStop == nil) // stream finished after stop
    }
    
    @Test("RecordRepository stores and retrieves unsynced records")
    func recordRepositoryPersists() async throws {
        let db = try Connection(.inMemory)
        let users = UserRepository(db: db)
        _ = try await users.createUser(name: "alice", passHash: "pass")
        
        let records = RecordRepository(db: db)
        let record = RandomRecord(id: "alice", value: 42, aiResponse: nil, isSynced: false)
        try await records.insertRecord(record)
        
        let unsynced = try await records.fetchUnsyncedRecords()
        #expect(unsynced.count == 1)
        #expect(unsynced.first?.value == 42)
    }
    
    @Test("SyncService marks unsynced records as synced")
    func syncServiceMarksRecords() async throws {
        let db = try Connection(.inMemory)
        let users = UserRepository(db: db)
        let user = try await users.createUser(name: "bob", passHash: "pass")
        
        let records = RecordRepository(db: db)
        let record = RandomRecord(id: user.id, value: 7, aiResponse: nil, isSynced: false)
        try await records.insertRecord(record)
        
        let sync = SyncService(recordsRepository: records, syncInterval: 0.05)
        sync.startSyncing()
        
        try await Task.sleep(nanoseconds: 200_000_000) // allow loop to run
        sync.stop()
        
        let remainingUnsynced = try await records.fetchUnsyncedRecords()
        #expect(remainingUnsynced.isEmpty)
    }
    
    @Test("SessionManager toggles login state")
    func sessionManagerAuthFlow() {
        let session = SessionManager()
        #expect(session.isLoggedIn == false)
        
        session.login(userId: "u1")
        #expect(session.isLoggedIn == true)
        #expect(session.currentUserId == "u1")
        
        session.logout()
        #expect(session.isLoggedIn == false)
        #expect(session.currentUserId == nil)
    }
    
    @Test("NetworkService decodes success and errors on bad status")
    @MainActor
    func networkServiceHandlesResponses() async throws {
        struct SampleResponse: Codable, Equatable { let value: Int }
        
        let okData = try JSONEncoder().encode(SampleResponse(value: 9))
        let okResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                         statusCode: 200,
                                         httpVersion: nil,
                                         headerFields: nil)!
        let badResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                          statusCode: 500,
                                          httpVersion: nil,
                                          headerFields: nil)!
        
        // Success path
        let okSession = MockSession(data: okData, response: okResponse)
        let okService = NetworkService(session: okSession)
        let request = URLRequest(url: URL(string: "https://example.com")!)
        let decoded: SampleResponse = try await okService.execute(request, responseType: SampleResponse.self)
        #expect(decoded == SampleResponse(value: 9))
        
        // Error path
        let badSession = MockSession(data: okData, response: badResponse)
        let badService = NetworkService(session: badSession)
        do {
            _ = try await badService.execute(request, responseType: SampleResponse.self)
            Issue.record("Expected NetworkError.httpError but call succeeded")
        } catch {
            if case NetworkError.httpError(let code) = error {
                #expect(code == 500)
            } else {
                Issue.record("Unexpected error type: \(error)")
            }
        }
    }
}

// MARK: - Test doubles

private struct MockSession: URLSessionProtocol {
    let data: Data
    let response: URLResponse
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return (data, response)
    }
}
