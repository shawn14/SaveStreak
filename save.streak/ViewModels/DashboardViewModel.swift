//
//  DashboardViewModel.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import SwiftUI
import SwiftData

/// View model for the main dashboard
@MainActor
@Observable
class DashboardViewModel {
    var showingAddSave = false
    var showingGoalSetup = false
    var saveAmount: String = ""

    private let modelContext: ModelContext
    private let notificationManager = NotificationManager.shared

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Record a new save entry for a goal
    func logSave(amount: Double, for goal: SavingsGoal) {
        // Convert to cents
        let amountCents = Int(amount * 100)

        // Create new save entry
        let entry = SaveEntry(
            amountCents: amountCents,
            date: Date(),
            goal: goal
        )

        // Add to context
        modelContext.insert(entry)

        // Update streak
        var mutableGoal = goal
        StreakCalculator.updateStreak(for: &mutableGoal, with: entry)

        // Save changes
        try? modelContext.save()

        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Check for milestone celebrations
        checkForMilestones(goal: goal)
    }

    /// Quick log with the default amount
    func quickLogSave(for goal: SavingsGoal) {
        logSave(amount: goal.savingsTarget, for: goal)
    }

    /// Check if we should celebrate any milestones
    private func checkForMilestones(goal: SavingsGoal) {
        let streak = goal.currentStreak

        // Celebrate streak milestones
        if streak == 7 {
            notificationManager.sendImmediateNotification(
                title: "🎉 One Week Streak!",
                body: "Amazing! You've saved for 7 days in a row!"
            )
        } else if streak == 30 {
            notificationManager.sendImmediateNotification(
                title: "🎉 30-Day Streak!",
                body: "Incredible dedication! A full month of saving!"
            )
        } else if streak == 100 {
            notificationManager.sendImmediateNotification(
                title: "🎉 100-Day Streak!",
                body: "You're a savings champion! 100 days strong!"
            )
        }

        // Celebrate goal completion
        if goal.isCompleted {
            notificationManager.sendImmediateNotification(
                title: "🎊 Goal Completed!",
                body: "Congratulations! You've reached your \(goal.name) goal!"
            )
        }

        // Celebrate halfway point
        if goal.progress >= 0.5 && goal.progress < 0.6 {
            notificationManager.sendImmediateNotification(
                title: "🎯 Halfway There!",
                body: "You're 50% of the way to your \(goal.name) goal!"
            )
        }
    }

    /// Get motivational message based on current state
    func getMotivationalMessage(for goal: SavingsGoal) -> String {
        if StreakCalculator.isStreakAtRisk(for: goal) && goal.currentStreak > 0 {
            return "⚠️ Don't break your \(goal.currentStreak)-day streak!"
        }

        if goal.progress >= 0.9 {
            return "Almost there! You're so close!"
        }

        if goal.currentStreak >= 7 {
            return "You're on fire! Keep it going!"
        }

        if goal.daysRemaining < 7 {
            return "Final push! \(goal.daysRemaining) days left!"
        }

        return "Every save counts. You got this! 💪"
    }

    /// Fetch the active goal (for free users, first goal; for premium, user can select)
    func fetchActiveGoal() -> SavingsGoal? {
        let descriptor = FetchDescriptor<SavingsGoal>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )

        do {
            let goals = try modelContext.fetch(descriptor)
            return goals.first
        } catch {
            print("Error fetching active goal: \(error)")
            return nil
        }
    }

    /// Get recent save history (last 30 days)
    func getRecentHistory(for goal: SavingsGoal) -> [SaveEntry] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()

        return goal.entries
            .filter { $0.date >= thirtyDaysAgo }
            .sorted { $0.date > $1.date }
    }

    /// Format currency
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
