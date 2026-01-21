//
//  NetworkManager.swift
//  TestApp
//
//  Created by Raju Dhumne on 18/01/26.
//

import Foundation


// MARK: - URLSession Protocol
/// Protocol for URLSession to enable dependency injection and testing
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Extension
extension URLSession: URLSessionProtocol {}

// MARK: - NetworkManager Protocol
/// Protocol defining network operations for dependency injection
protocol NetworkServiceProtocol {
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T
}

/// NetworkManager handles executing URLRequests and decoding responses
/// Provides a clean interface for network operations with error handling
final class NetworkService: NetworkServiceProtocol {
    
    private let session: URLSessionProtocol
    
    /// Initializes NetworkManager with a URLSession
    /// - Parameter session: URLSession to use for network requests (defaults to shared)
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    /// Executes a URLRequest and decodes the response
    /// - Parameters:
    ///   - request: The URLRequest to execute
    ///   - responseType: The type to decode the response to
    /// - Returns: Decoded response object
    /// - Throws: NetworkError for various failure cases
    func execute<T: Decodable>(_ request: URLRequest, responseType: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        print(httpResponse)
        guard 200...299 ~= httpResponse.statusCode else {
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}

/// Network-related errors that can occur during API calls
enum NetworkError: Error {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    
    /// Human-readable description of the error
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
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}
