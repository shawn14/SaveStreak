//
//  GoalCoach.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// AI-powered conversational coach for savings goals
@MainActor
class GoalCoach: ObservableObject {
    @Published var conversation: [ChatMessage] = []
    @Published var isThinking = false

    private let aiService = AIService.shared
    private let systemPrompt = """
    You are SaveStreak's AI financial coach - friendly, encouraging, and practical.

    Your role:
    - Help users set realistic savings goals
    - Provide personalized saving strategies
    - Answer questions about their progress
    - Offer encouragement and motivation
    - Give actionable financial advice

    Guidelines:
    - Keep responses concise (2-3 sentences max)
    - Be supportive and non-judgmental
    - Focus on small, achievable actions
    - Use simple language
    - Include 1-2 emojis when appropriate
    - Never give investment advice or complex financial products

    Context: Users are trying to build daily/weekly saving habits using a streak-based app.
    """

    /// Start a new conversation
    func startConversation(with greeting: String? = nil) {
        conversation = []

        if let greeting = greeting {
            let systemMessage = ChatMessage(role: .system, content: systemPrompt)
            let userMessage = ChatMessage(role: .user, content: greeting)
            conversation = [systemMessage, userMessage]
        }
    }

    /// Send a message and get AI response
    func sendMessage(_ message: String) async {
        // Add user message
        let userMessage = ChatMessage(role: .user, content: message)
        conversation.append(userMessage)

        isThinking = true
        defer { isThinking = false }

        do {
            // Prepare messages for API (include system prompt)
            var apiMessages = conversation
            if conversation.first?.role != .system {
                apiMessages.insert(ChatMessage(role: .system, content: systemPrompt), at: 0)
            }

            // Get AI response
            let response = try await aiService.chatCompletion(
                messages: apiMessages,
                maxTokens: 200,
                temperature: 0.8
            )

            // Add assistant response
            let assistantMessage = ChatMessage(role: .assistant, content: response)
            conversation.append(assistantMessage)

        } catch {
            // Add error message
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. Please try again in a moment. 🤔"
            )
            conversation.append(errorMessage)
        }
    }

    /// Ask about a specific goal
    func askAboutGoal(_ goal: SavingsGoal, question: String) async {
        let contextualQuestion = """
        \(question)

        [My goal: "\(goal.name)", Target: $\(goal.targetAmount), Saved: $\(goal.totalSaved), \
        Streak: \(goal.currentStreak) days, Progress: \(Int(goal.progress * 100))%]
        """

        await sendMessage(contextualQuestion)
    }

    /// Get advice on adjusting a goal
    func getAdjustmentAdvice(for goal: SavingsGoal) async {
        let prompt: String

        if goal.daysRemaining < 0 {
            prompt = """
            My deadline passed but I've only saved $\(goal.totalSaved) of $\(goal.targetAmount). \
            What should I do?
            """
        } else if goal.progress < 0.3 && goal.daysRemaining < 10 {
            prompt = """
            I'm only at \(Int(goal.progress * 100))% of my goal with \(goal.daysRemaining) days left. \
            Should I adjust my target?
            """
        } else {
            prompt = "Am I on track to reach my \"\(goal.name)\" goal?"
        }

        startConversation()
        await sendMessage(prompt)
    }

    /// Get celebration message for achievement
    func celebrate(achievement: Achievement, for goal: SavingsGoal) async -> String? {
        let prompt: String

        switch achievement {
        case .streakMilestone(let days):
            prompt = "I just hit a \(days)-day saving streak for my \"\(goal.name)\" goal! 🔥"

        case .goalCompleted:
            prompt = "I completed my \"\(goal.name)\" goal of $\(goal.targetAmount)! 🎉"

        case .halfwayMark:
            prompt = "I'm halfway to my \"\(goal.name)\" goal!"

        case .savedMore(let amount):
            prompt = "I saved $\(amount) extra today! More than my usual target."
        }

        startConversation()
        await sendMessage(prompt)

        return conversation.last?.content
    }

    /// Clear conversation history
    func clearConversation() {
        conversation = []
    }
}

// MARK: - Achievement Types

enum Achievement {
    case streakMilestone(days: Int)
    case goalCompleted
    case halfwayMark
    case savedMore(amount: Double)
}
