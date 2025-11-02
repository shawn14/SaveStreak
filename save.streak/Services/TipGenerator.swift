//
//  TipGenerator.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation

/// Generates personalized daily saving tips using AI
struct TipGenerator {
    private let aiService = AIService.shared

    /// Generate a daily saving tip based on user's goal
    /// - Parameter goal: The user's active savings goal
    /// - Returns: Personalized tip string
    func generateDailyTip(for goal: SavingsGoal) async throws -> String {
        let systemPrompt = """
        You are a friendly, encouraging financial coach helping people save money.
        Generate a short, actionable daily saving tip (1-2 sentences max).
        Be specific, practical, and motivating.
        Focus on small, achievable actions.
        Use emojis sparingly (1-2 max).
        """

        let userPrompt = """
        User's savings goal: \(goal.name)
        Target amount: $\(goal.targetAmount)
        Daily saving target: $\(goal.savingsTarget)
        Current streak: \(goal.currentStreak) days
        Progress: \(Int(goal.progress * 100))%
        Days remaining: \(goal.daysRemaining)

        Generate one specific, actionable tip to help them save today.
        """

        return try await aiService.quickCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 100
        )
    }

    /// Generate a motivational message for a specific situation
    func generateMotivation(
        for goal: SavingsGoal,
        situation: MotivationalContext
    ) async throws -> String {
        let systemPrompt = """
        You are an enthusiastic financial coach.
        Write a short, uplifting message (1 sentence).
        Be genuine and encouraging.
        """

        let userPrompt: String

        switch situation {
        case .streakAtRisk:
            userPrompt = """
            The user has a \(goal.currentStreak)-day streak for their "\(goal.name)" goal.
            They haven't saved today yet. Encourage them to keep the streak alive.
            """

        case .halfwayPoint:
            userPrompt = """
            The user just reached 50% of their "\(goal.name)" goal ($\(goal.targetAmount)).
            Celebrate this milestone!
            """

        case .finalPush:
            userPrompt = """
            The user is at \(Int(goal.progress * 100))% of their "\(goal.name)" goal.
            Only \(goal.daysRemaining) days left. Motivate them for the final stretch!
            """

        case .goalCompleted:
            userPrompt = """
            The user just completed their "\(goal.name)" goal of $\(goal.targetAmount)!
            Congratulate them enthusiastically!
            """

        case .newStreak(let days):
            userPrompt = """
            The user just hit a \(days)-day saving streak for "\(goal.name)".
            Celebrate this achievement!
            """
        }

        return try await aiService.quickCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 80
        )
    }

    /// Generate goal suggestions based on user input
    func suggestGoal(description: String) async throws -> GoalSuggestion {
        let systemPrompt = """
        You are a financial planning assistant.
        Based on the user's description, suggest a realistic savings goal.
        Respond ONLY in this exact JSON format:
        {
          "goalName": "short name for the goal",
          "targetAmount": number (realistic amount in dollars),
          "suggestedMonths": number (realistic timeline in months),
          "reasoning": "brief explanation"
        }
        """

        let userPrompt = "User wants to save for: \(description)"

        let response = try await aiService.quickCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            maxTokens: 200
        )

        // Parse JSON response
        guard let jsonData = response.data(using: .utf8),
              let suggestion = try? JSONDecoder().decode(GoalSuggestion.self, from: jsonData) else {
            throw AIError.invalidResponse
        }

        return suggestion
    }
}

// MARK: - Supporting Types

enum MotivationalContext {
    case streakAtRisk
    case halfwayPoint
    case finalPush
    case goalCompleted
    case newStreak(days: Int)
}

struct GoalSuggestion: Codable {
    let goalName: String
    let targetAmount: Double
    let suggestedMonths: Int
    let reasoning: String
}
