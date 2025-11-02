//
//  SavingsGoal.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Represents a savings goal with target amount, deadline, and tracking information
@Model
final class SavingsGoal {
    /// Unique identifier for the goal
    var id: UUID

    /// Name/title of the savings goal (e.g., "Emergency Fund", "Vacation")
    var name: String

    /// Target amount to save (in cents to avoid floating point issues)
    var targetAmountCents: Int

    /// Deadline date to reach the goal
    var deadline: Date

    /// Amount to save per period (daily or weekly) in cents
    var savingsTargetCents: Int

    /// Frequency of saving: true for daily, false for weekly
    var isDaily: Bool

    /// Date when this goal was created
    var createdAt: Date

    /// Current streak count (consecutive periods where user met the target)
    var currentStreak: Int

    /// Longest streak ever achieved for this goal
    var longestStreak: Int

    /// Last date a save entry was recorded
    var lastSaveDate: Date?

    /// Whether this goal is active or archived
    var isActive: Bool

    /// Optional emoji or icon identifier
    var icon: String?

    /// Relationship to save entries
    @Relationship(deleteRule: .cascade, inverse: \SaveEntry.goal)
    var entries: [SaveEntry] = []

    /// Computed property: target amount in dollars
    var targetAmount: Double {
        Double(targetAmountCents) / 100.0
    }

    /// Computed property: savings target in dollars
    var savingsTarget: Double {
        Double(savingsTargetCents) / 100.0
    }

    /// Computed property: total amount saved so far
    var totalSaved: Double {
        entries.reduce(0) { $0 + $1.amount }
    }

    /// Computed property: progress percentage (0.0 to 1.0)
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(totalSaved / targetAmount, 1.0)
    }

    /// Computed property: days remaining until deadline
    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0
    }

    /// Computed property: is the goal completed?
    var isCompleted: Bool {
        totalSaved >= targetAmount
    }

    init(
        name: String,
        targetAmountCents: Int,
        deadline: Date,
        savingsTargetCents: Int,
        isDaily: Bool = true,
        icon: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.targetAmountCents = targetAmountCents
        self.deadline = deadline
        self.savingsTargetCents = savingsTargetCents
        self.isDaily = isDaily
        self.createdAt = Date()
        self.currentStreak = 0
        self.longestStreak = 0
        self.isActive = true
        self.icon = icon
    }
}
