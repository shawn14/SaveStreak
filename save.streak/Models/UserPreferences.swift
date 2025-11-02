//
//  UserPreferences.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import SwiftData

/// Stores user preferences and settings (single instance per app)
@Model
final class UserPreferences {
    /// Primary notification time (24-hour format: 0-23)
    var primaryNotificationHour: Int

    /// Primary notification minute (0-59)
    var primaryNotificationMinute: Int

    /// Whether notifications are enabled
    var notificationsEnabled: Bool

    /// Optional second reminder time (evening nudge)
    var secondaryNotificationHour: Int?
    var secondaryNotificationMinute: Int?

    /// Whether user has premium access
    var isPremium: Bool

    /// Date when premium was purchased (if applicable)
    var premiumPurchaseDate: Date?

    /// Whether user prefers weekly reminders (vs daily)
    var weeklyRemindersEnabled: Bool

    /// Day of week for weekly reminders (1 = Sunday, 7 = Saturday)
    var weeklyReminderDay: Int

    /// Whether to show motivational tips
    var showMotivationalTips: Bool

    /// App theme preference (for future use)
    var themePreference: String

    /// When user completed onboarding
    var onboardingCompletedDate: Date?

    /// Whether AI daily tips are enabled (Premium feature)
    var aiTipsEnabled: Bool

    /// Whether AI goal coach is enabled (Premium feature)
    var aiCoachEnabled: Bool

    /// Last generated daily tip
    var lastDailyTip: String?

    /// Date when last tip was generated
    var lastTipDate: Date?

    /// AI Coach conversations used today (Free tier limit: 3/day)
    var aiCoachConversationsToday: Int

    /// Date of last AI coach conversation (to reset daily counter)
    var lastAICoachDate: Date?

    init() {
        // Default: 9:00 AM notification
        self.primaryNotificationHour = 9
        self.primaryNotificationMinute = 0
        self.notificationsEnabled = true

        // No secondary notification by default
        self.secondaryNotificationHour = nil
        self.secondaryNotificationMinute = nil

        // Free tier by default
        self.isPremium = false
        self.premiumPurchaseDate = nil

        // Daily reminders by default
        self.weeklyRemindersEnabled = false
        self.weeklyReminderDay = 1 // Sunday

        // Tips enabled by default
        self.showMotivationalTips = true

        // Default theme
        self.themePreference = "default"

        // AI features enabled by default (now available for free tier!)
        self.aiTipsEnabled = true
        self.aiCoachEnabled = true
        self.lastDailyTip = nil
        self.lastTipDate = nil

        // AI usage tracking for free tier
        self.aiCoachConversationsToday = 0
        self.lastAICoachDate = nil
    }

    // MARK: - AI Usage Helpers

    /// Check if user can use AI Coach (free: 3/day, premium: unlimited)
    func canUseAICoach(isPremium: Bool) -> Bool {
        if isPremium { return true }

        // Reset counter if it's a new day
        if let lastDate = lastAICoachDate,
           !Calendar.current.isDateInToday(lastDate) {
            aiCoachConversationsToday = 0
        }

        return aiCoachConversationsToday < 3
    }

    /// Increment AI Coach usage counter
    mutating func incrementAICoachUsage() {
        // Reset if new day
        if let lastDate = lastAICoachDate,
           !Calendar.current.isDateInToday(lastDate) {
            aiCoachConversationsToday = 0
        }

        aiCoachConversationsToday += 1
        lastAICoachDate = Date()
    }

    /// Get remaining AI Coach conversations for today (free tier)
    func remainingAICoachConversations(isPremium: Bool) -> Int? {
        if isPremium { return nil } // Unlimited

        // Reset if new day
        if let lastDate = lastAICoachDate,
           !Calendar.current.isDateInToday(lastDate) {
            return 3
        }

        return max(0, 3 - aiCoachConversationsToday)
    }
}
