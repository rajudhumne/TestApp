//
//  NetworkManager.swift
//  TestApp
//
//  Created by Raju Dhumne on 18/01/26.
//
//  NetworkService provides a clean abstraction layer for network operations.
//  It handles HTTP requests, response validation, and JSON decoding with proper error handling.

import Foundation


// MARK: - URLSession Protocol
/// Protocol for URLSession to enable dependency injection and testing
/// This allows us to mock URLSession in unit tests
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Extension
/// Conforms URLSession to our protocol for dependency injection
extension URLSession: URLSessionProtocol {}

// MARK: - NetworkManager Protocol
/// Protocol defining network operations for dependency injection
/// Enables testability by allowing mock implementations
protocol NetworkServiceProtocol {
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
}

// MARK: - NetworkService
/// NetworkService handles executing URLRequests and decoding responses
/// Provides a clean interface for network operations with error handling
/// 
/// Features:
/// - Generic response decoding
/// - HTTP status code validation
/// - Comprehensive error handling
/// - Dependency injection support for testing
final class NetworkService: NetworkServiceProtocol {
    
    // MARK: - Properties
    
    /// The URLSession used for network requests (injectable for testing)
    private let session: URLSessionProtocol
    
    // MARK: - Initialization
    
    /// Initializes NetworkService with a URLSession
    /// - Parameter session: URLSession to use for network requests (defaults to shared)
    ///   Can be injected for testing purposes
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Executes a URLRequest and decodes the response to the specified type
    /// 
    /// This method:
    /// 1. Performs the network request
    /// 2. Validates the HTTP response status code (200-299)
    /// 3. Decodes the JSON response to the specified type
    /// 
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - responseType: The type to decode the response to (must conform to Decodable)
    /// - Returns: Decoded response object of type T
    /// - Throws: NetworkError for various failure cases:
    ///   - `.invalidResponse` if response is not HTTPURLResponse
    ///   - `.httpError(code)` if status code is not 2xx
    ///   - `.decodingError(error)` if JSON decoding fails
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        // Perform the network request
        let (data, response) = try await session.data(for: request)
        
        // Validate response type
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Log response for debugging (consider removing in production)
        print(httpResponse)
        
        // Validate HTTP status code (success range: 200-299)
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        // Decode JSON response
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            // Wrap decoding errors in our error type
            throw NetworkError.decodingError(error)
        }
    }
}

// MARK: - NetworkError
/// Network-related errors that can occur during API calls
/// 
/// Error cases:
/// - `invalidResponse`: Response is not a valid HTTP response
/// - `httpError(code)`: HTTP status code indicates an error (non-2xx)
/// - `decodingError(error)`: JSON decoding failed
enum NetworkError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    /// Human-readable description of the error for user-facing messages
    var localizedDescription: String {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - HTTPMethod
/// HTTP methods supported by the network layer
/// Used for constructing URLRequests with the appropriate HTTP method
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
