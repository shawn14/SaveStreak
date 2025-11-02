//
//  AIService.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation

/// Service for interacting with OpenAI API (GPT-4o mini)
@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    // MARK: - Configuration
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini" // Cost-effective model

    @Published var isLoading = false
    @Published var lastError: String?

    private init() {
        // Load API key from UserDefaults or environment
        // In production, you'd store this securely in Keychain
        self.apiKey = UserDefaults.standard.string(forKey: "OPENAI_API_KEY") ?? ""
    }

    // MARK: - API Key Management

    /// Set the OpenAI API key
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OPENAI_API_KEY")
    }

    /// Check if API key is configured
    var hasAPIKey: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Chat Completion

    /// Send a chat completion request to OpenAI
    /// - Parameters:
    ///   - messages: Array of chat messages (system, user, assistant)
    ///   - maxTokens: Maximum tokens in response (default: 150)
    ///   - temperature: Creativity level 0-2 (default: 0.7)
    /// - Returns: AI response text
    func chatCompletion(
        messages: [ChatMessage],
        maxTokens: Int = 150,
        temperature: Double = 0.7
    ) async throws -> String {
        guard hasAPIKey else {
            throw AIError.noAPIKey
        }

        isLoading = true
        defer { isLoading = false }

        // Build request
        let requestBody = ChatCompletionRequest(
            model: model,
            messages: messages.map { $0.toAPIMessage() },
            maxTokens: maxTokens,
            temperature: temperature
        )

        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error
            if let errorResponse = try? JSONDecoder().decode(OpenAIError.self, from: data) {
                throw AIError.apiError(errorResponse.error.message)
            }
            throw AIError.httpError(httpResponse.statusCode)
        }

        // Parse response
        let completionResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)

        guard let content = completionResponse.choices.first?.message.content else {
            throw AIError.emptyResponse
        }

        return content
    }

    /// Quick single-prompt completion (convenience method)
    func quickCompletion(
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int = 150
    ) async throws -> String {
        let messages: [ChatMessage] = [
            ChatMessage(role: .system, content: systemPrompt),
            ChatMessage(role: .user, content: userPrompt)
        ]

        return try await chatCompletion(messages: messages, maxTokens: maxTokens)
    }
}

// MARK: - Models

/// Chat message for conversation
struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date

    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    fileprivate func toAPIMessage() -> APIChatMessage {
        APIChatMessage(role: role.rawValue, content: content)
    }
}

enum MessageRole: String, Codable {
    case system
    case user
    case assistant
}

// MARK: - API Request/Response Models

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [APIChatMessage]
    let maxTokens: Int
    let temperature: Double

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case maxTokens = "max_tokens"
        case temperature
    }
}

private struct APIChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: APIChatMessage
    }
}

private struct OpenAIError: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from AI service."
        case .httpError(let code):
            return "AI service error (HTTP \(code))."
        case .apiError(let message):
            return "AI error: \(message)"
        case .emptyResponse:
            return "AI returned an empty response."
        }
    }
}
