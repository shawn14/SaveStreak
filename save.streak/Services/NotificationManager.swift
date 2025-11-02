//
//  NotificationManager.swift
//  SaveStreak
//
//  Created by Claude Code
//

import Foundation
import UserNotifications
import SwiftUI

/// Manages local push notifications for savings reminders
@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    /// Request notification permissions from user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            self.isAuthorized = granted
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }

    /// Check current authorization status
    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        self.isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Schedule daily reminder notifications
    /// - Parameters:
    ///   - hour: Hour in 24-hour format (0-23)
    ///   - minute: Minute (0-59)
    ///   - goalName: Name of the goal for personalized message
    func scheduleDailyReminder(hour: Int, minute: Int, goalName: String = "savings goal") {
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Save! 💰"
        content.body = "Don't break your streak! Log today's contribution to \(goalName)."
        content.sound = .default
        content.categoryIdentifier = "SAVE_REMINDER"

        // Create date components for trigger
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        // Create trigger (repeats daily)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: "daily-reminder-primary",
            content: content,
            trigger: trigger
        )

        // Schedule notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    /// Schedule secondary (evening) reminder
    func scheduleSecondaryReminder(hour: Int, minute: Int, goalName: String = "savings goal") {
        let content = UNMutableNotificationContent()
        content.title = "Evening Reminder 🌙"
        content.body = "Did you log your save for \(goalName) today?"
        content.sound = .default
        content.categoryIdentifier = "SAVE_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-reminder-secondary",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling secondary notification: \(error)")
            }
        }
    }

    /// Schedule weekly reminder
    /// - Parameters:
    ///   - weekday: Day of week (1 = Sunday, 7 = Saturday)
    ///   - hour: Hour in 24-hour format
    ///   - minute: Minute
    func scheduleWeeklyReminder(weekday: Int, hour: Int, minute: Int, goalName: String = "savings goal") {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Save Time! 📅"
        content.body = "This week's contribution to \(goalName) is due. Keep your streak alive!"
        content.sound = .default
        content.categoryIdentifier = "SAVE_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-reminder",
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling weekly notification: \(error)")
            }
        }
    }

    /// Cancel all scheduled notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }

    /// Cancel specific notification by identifier
    func cancelNotification(withIdentifier identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    /// Get all pending notifications (for debugging/settings display)
    func getPendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }

    /// Send immediate motivational notification (for testing or milestone celebrations)
    func sendImmediateNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Trigger after 1 second
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        notificationCenter.add(request)
    }

    /// Update all notifications based on user preferences
    func updateNotifications(preferences: UserPreferences, activeGoal: SavingsGoal?) {
        // Cancel existing notifications
        cancelAllNotifications()

        // Only schedule if enabled and we have a goal
        guard preferences.notificationsEnabled, let goal = activeGoal else {
            return
        }

        if preferences.weeklyRemindersEnabled {
            // Schedule weekly reminder
            scheduleWeeklyReminder(
                weekday: preferences.weeklyReminderDay,
                hour: preferences.primaryNotificationHour,
                minute: preferences.primaryNotificationMinute,
                goalName: goal.name
            )
        } else {
            // Schedule daily reminder
            scheduleDailyReminder(
                hour: preferences.primaryNotificationHour,
                minute: preferences.primaryNotificationMinute,
                goalName: goal.name
            )

            // Schedule secondary reminder if set and user is premium
            if preferences.isPremium,
               let secondHour = preferences.secondaryNotificationHour,
               let secondMinute = preferences.secondaryNotificationMinute {
                scheduleSecondaryReminder(
                    hour: secondHour,
                    minute: secondMinute,
                    goalName: goal.name
                )
            }
        }
    }
}
