//
//  LocalLLMService.swift
//  TestApp
//
//  Created by Raju Dhumne on 18/01/26.
//
//  LocalLLMService provides integration with local LLM services (Ollama).
//  Handles AI text generation requests and responses.

import Foundation

// MARK: - LLMRequest
/// Request structure for LLM generation (currently unused, kept for future use)
struct LLMRequest: Codable {
    let model: LocalLLMModelType
    let prompt: String
}

// MARK: - LocalLLMModelType
/// Supported local LLM models available through Ollama
enum LocalLLMModelType: String, Codable {
    case tinyLlama = "tinyllama"  // Small, fast model
    case mistral = "mistral"       // Mistral model variant
    case llama3 = "llama3"         // Llama 3 model
}

// MARK: - LLMResponse
/// Response structure from LLM generation API
struct LLMResponse: Codable {
    let response: String  // Generated text response
}

// MARK: - LLMClient Protocol
/// Protocol defining LLM client interface for dependency injection
protocol LLMClient {
    /// Generates text using the specified model and prompt
    /// - Parameters:
    ///   - model: The LLM model to use for generation
    ///   - prompt: The input prompt for text generation
    /// - Returns: Generated text string
    /// - Throws: Network errors if the request fails
    func generate(using model: LocalLLMModelType, prompt: String) async throws -> String
}

// MARK: - OllamaLLM
/// Client for interacting with Ollama local LLM service
/// 
/// Ollama is a tool for running large language models locally.
/// This client connects to Ollama's API (typically at localhost:11434).
/// 
/// Features:
/// - Support for multiple model types
/// - Async/await interface
/// - Network error handling
final class OllamaLLM: LLMClient {
    
    // MARK: - Properties
    
    /// Network service for making HTTP requests to Ollama API
    let networkService: NetworkServiceProtocol
    
    // MARK: - Initialization
    
    /// Initializes the Ollama LLM client
    /// - Parameter networkService: Network service for API calls (injectable for testing)
    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
    
    // MARK: - Public Methods
    
    /// Generates text using the specified Ollama model
    /// 
    /// Process:
    /// 1. Creates an Ollama API request with the model and prompt
    /// 2. Executes the request via NetworkService
    /// 3. Returns the generated response text
    /// 
    /// - Parameters:
    ///   - model: The LLM model to use (e.g., .tinyLlama)
    ///   - prompt: The input text prompt
    /// - Returns: Generated text response from the model
    /// - Throws: NetworkError if the API request fails
    func generate(using model: LocalLLMModelType, prompt: String) async throws -> String {
        // Create API request using Ollama endpoint
        let request = try OllamaEndpoint
            .generate(model: model.rawValue, prompt: prompt)
            .makeRequest()
        
        // Execute request and decode response
        let requestData = try await networkService.execute(request, responseType: LLMResponse.self)
        
        // Extract and return the generated text
        return requestData.response
    }
}
