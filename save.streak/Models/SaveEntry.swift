//
//  SaveEntry.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Represents a single save transaction/contribution toward a goal
@Model
final class SaveEntry {
    /// Unique identifier
    var id: UUID

    /// Date when this save was recorded
    var date: Date

    /// Amount saved in cents
    var amountCents: Int

    /// Optional note from the user
    var note: String?

    /// Reference to the parent goal
    var goal: SavingsGoal?

    /// Computed property: amount in dollars
    var amount: Double {
        Double(amountCents) / 100.0
    }

    init(
        amountCents: Int,
        date: Date = Date(),
        note: String? = nil,
        goal: SavingsGoal? = nil
    ) {
        self.id = UUID()
        self.amountCents = amountCents
        self.date = date
        self.note = note
        self.goal = goal
    }
}
