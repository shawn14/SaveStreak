//
//  StreakCalculator.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation

/// Utility for calculating and managing saving streaks
struct StreakCalculator {

    /// Calculate the current streak for a goal based on its save entries
    /// - Parameters:
    ///   - goal: The savings goal to calculate streak for
    ///   - entries: Array of save entries, should be sorted by date descending
    /// - Returns: Current streak count (number of consecutive periods met)
    static func calculateCurrentStreak(for goal: SavingsGoal, entries: [SaveEntry]) -> Int {
        // Sort entries by date, most recent first
        let sortedEntries = entries.sorted { $0.date > $1.date }

        guard !sortedEntries.isEmpty else { return 0 }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Group entries by day or week depending on goal frequency
        let groupedEntries: [Date: [SaveEntry]]
        if goal.isDaily {
            groupedEntries = Dictionary(grouping: sortedEntries) { entry in
                calendar.startOfDay(for: entry.date)
            }
        } else {
            // For weekly: group by week start date (Sunday)
            groupedEntries = Dictionary(grouping: sortedEntries) { entry in
                let weekday = calendar.component(.weekday, from: entry.date)
                let daysToSubtract = weekday - 1 // Sunday = 1, so 0 days to subtract
                return calendar.date(byAdding: .day, value: -daysToSubtract, to: calendar.startOfDay(for: entry.date))!
            }
        }

        var streak = 0
        var checkDate = today

        // Check if we should allow today's save
        let todayTotal = groupedEntries[checkDate]?.reduce(0) { $0 + $1.amountCents } ?? 0

        // Start from current period
        while true {
            let periodStart: Date
            if goal.isDaily {
                periodStart = checkDate
            } else {
                // Get week start
                let weekday = calendar.component(.weekday, from: checkDate)
                let daysToSubtract = weekday - 1
                periodStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: checkDate)!
            }

            // Get total saved in this period
            let periodTotal = groupedEntries[periodStart]?.reduce(0) { $0 + $1.amountCents } ?? 0

            // Check if target was met
            if periodTotal >= goal.savingsTargetCents {
                streak += 1
            } else {
                // Streak is broken, but allow grace for today if no save yet
                if periodStart == today {
                    // Today hasn't been completed yet, that's okay
                    break
                } else {
                    // Streak is broken in the past
                    break
                }
            }

            // Move to previous period
            if goal.isDaily {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            } else {
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkDate) else { break }
                checkDate = previousWeek
            }

            // Safety: don't go back more than 1 year
            if let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: today),
               checkDate < oneYearAgo {
                break
            }
        }

        return streak
    }

    /// Check if a save was logged today (or this week for weekly goals)
    static func hasSavedToday(for goal: SavingsGoal, entries: [SaveEntry]) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if goal.isDaily {
            // Check if any entry is from today
            return entries.contains { entry in
                calendar.isDate(entry.date, inSameDayAs: today)
            }
        } else {
            // Check if any entry is from this week
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
                return false
            }

            return entries.contains { entry in
                let entryWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: entry.date))
                return entryWeekStart == weekStart
            }
        }
    }

    /// Update goal's streak based on a new save entry
    /// - Parameters:
    ///   - goal: Goal to update
    ///   - newEntry: The save entry just added
    static func updateStreak(for goal: inout SavingsGoal, with newEntry: SaveEntry) {
        // Recalculate current streak
        let allEntries = goal.entries
        let newStreak = calculateCurrentStreak(for: goal, entries: allEntries)

        goal.currentStreak = newStreak

        // Update longest streak if needed
        if newStreak > goal.longestStreak {
            goal.longestStreak = newStreak
        }

        // Update last save date
        goal.lastSaveDate = newEntry.date
    }

    /// Get the streak status message for display
    static func streakMessage(for goal: SavingsGoal) -> String {
        let streak = goal.currentStreak

        if streak == 0 {
            return "Start your streak today!"
        } else if streak == 1 {
            return "🔥 1 \(goal.isDaily ? "day" : "week") streak!"
        } else {
            return "🔥 \(streak) \(goal.isDaily ? "day" : "week") streak!"
        }
    }

    /// Calculate how many more saves are needed to reach the goal
    static func savesRemaining(for goal: SavingsGoal) -> Int {
        let totalNeeded = goal.targetAmountCents
        let totalSaved = Int(goal.totalSaved * 100)
        let remaining = totalNeeded - totalSaved

        if remaining <= 0 {
            return 0
        }

        return Int(ceil(Double(remaining) / Double(goal.savingsTargetCents)))
    }

    /// Check if a streak is about to be broken (no save today/this week yet)
    static func isStreakAtRisk(for goal: SavingsGoal) -> Bool {
        guard goal.currentStreak > 0 else { return false }

        let entries = goal.entries
        return !hasSavedToday(for: goal, entries: entries)
    }

    /// Get days/weeks since last save
    static func daysSinceLastSave(for goal: SavingsGoal) -> Int? {
        guard let lastSave = goal.lastSaveDate else { return nil }

        let calendar = Calendar.current

        if goal.isDaily {
            return calendar.dateComponents([.day], from: calendar.startOfDay(for: lastSave), to: calendar.startOfDay(for: Date())).day
        } else {
            return calendar.dateComponents([.weekOfYear], from: lastSave, to: Date()).weekOfYear
        }
    }
}
