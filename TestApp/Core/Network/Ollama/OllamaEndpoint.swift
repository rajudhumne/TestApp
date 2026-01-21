//
//  OllamaEndpoint.swift
//  TestApp
//
//  Created by Raju Dhumne on 20/01/26.
//
//  OllamaEndpoint defines API endpoints for the Ollama local LLM service.
//  Handles request construction for text generation and model management.

import Foundation

// MARK: - OllamaEndpoint
/// Enum representing Ollama API endpoints
/// 
/// Provides type-safe endpoint definitions and request construction.
enum OllamaEndpoint {
    /// Generate text using a specified model
    /// - Parameters:
    ///   - model: Model name (e.g., "tinyllama")
    ///   - prompt: Input text prompt
    ///   - stream: Whether to stream the response (default: false)
    case generate(model: String, prompt: String, stream: Bool = false)
    
    /// List available models
    case tags

    // MARK: - Path Resolution
    
    /// Returns the API path for the endpoint
    private var path: String {
        switch self {
        case .generate:
            return "/api/generate"
        case .tags:
            return "/api/tags"
        }
    }

    // MARK: - HTTP Method
    
    /// Returns the HTTP method for the endpoint
    private var method: String {
        switch self {
        case .generate:
            return "POST"
        case .tags:
            return "GET"
        }
    }

    // MARK: - Request Construction
    
    /// Constructs a URLRequest for the endpoint
    /// 
    /// Creates a properly formatted HTTP request with:
    /// - Correct URL path
    /// - Appropriate HTTP method
    /// - JSON content type header
    /// - Request body for POST requests
    /// 
    /// - Parameter baseURL: Base URL for Ollama API (default: http://localhost:11434)
    /// - Returns: Configured URLRequest ready for execution
    /// - Throws: Error if JSON serialization fails
    func makeRequest(baseURL: URL = URL(string: "http://localhost:11434")!) throws -> URLRequest {
        // Construct full URL
        let url = baseURL.appendingPathComponent(path)
        
        // Create request with HTTP method
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add request body for POST endpoints
        switch self {
        case let .generate(model, prompt, stream):
            // Construct JSON body for generation request
            let body = [
                "model": model,
                "prompt": prompt,
                "stream": stream
            ] as [String: Any]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

        case .tags:
            // GET request, no body needed
            break
        }

        return request
    }
}
