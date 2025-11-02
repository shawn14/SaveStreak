//
//  SettingsView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var userPreferences: [UserPreferences]
    @Query private var goals: [SavingsGoal]

    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var storeManager = StoreManager.shared

    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    @State private var apiKey = ""
    @State private var showingAPIKeyInput = false

    private var preferences: UserPreferences {
        if let existing = userPreferences.first {
            return existing
        } else {
            let newPrefs = UserPreferences()
            modelContext.insert(newPrefs)
            try? modelContext.save()
            return newPrefs
        }
    }

    var body: some View {
        List {
            // Premium Status
            premiumSection

            // AI Features (Available to all users)
            aiSection

            // Notifications
            notificationSection

            // Goals Management
            goalsSection

            // About
            aboutSection
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .task {
            await notificationManager.checkAuthorizationStatus()
        }
    }

    // MARK: - Premium Section
    @ViewBuilder
    private var premiumSection: some View {
        Section {
            if storeManager.isPremium {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundStyle(.yellow)
                    Text("Premium Active")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            } else {
                // DEVELOPMENT: Enable Premium for testing
                Button(action: {
                    // Toggle premium for testing
                    preferences.isPremium.toggle()
                    preferences.premiumPurchaseDate = Date()
                    try? modelContext.save()
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundStyle(.yellow)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Upgrade to Premium")
                                .fontWeight(.semibold)
                            Text("Unlimited goals, multiple reminders & more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if storeManager.isPremium {
                Button("Restore Purchases") {
                    Task {
                        await storeManager.restorePurchases()
                    }
                }
            }
        } header: {
            Text("Premium")
        }
    }

    // MARK: - AI Section
    @ViewBuilder
    private var aiSection: some View {
        Section {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.purple)
                Text("API Key")
                Spacer()
                if AIService.shared.hasAPIKey {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Configured")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not Set")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingAPIKeyInput = true
            }

            Toggle("Daily AI Tips", isOn: Binding(
                get: { preferences.aiTipsEnabled },
                set: { newValue in
                    preferences.aiTipsEnabled = newValue
                    try? modelContext.save()
                }
            ))

            Toggle("AI Coach", isOn: Binding(
                get: { preferences.aiCoachEnabled },
                set: { newValue in
                    preferences.aiCoachEnabled = newValue
                    try? modelContext.save()
                }
            ))
        } header: {
            Text("AI Features")
        } footer: {
            if !AIService.shared.hasAPIKey {
                Text("Add your OpenAI API key to enable AI features. Your key is stored securely on your device.")
            } else if !storeManager.isPremium {
                Text("Free tier: 1 daily tip, 3 AI Coach conversations per day. Upgrade to Premium for unlimited access.")
            }
        }
        .alert("OpenAI API Key", isPresented: $showingAPIKeyInput) {
            TextField("sk-proj-...", text: $apiKey)
                .textContentType(.password)
            Button("Cancel", role: .cancel) {
                apiKey = ""
            }
            Button("Save") {
                AIService.shared.setAPIKey(apiKey)
                apiKey = ""
            }
        } message: {
            Text("Enter your OpenAI API key. Get one at platform.openai.com")
        }
    }

    // MARK: - Notification Section
    @ViewBuilder
    private var notificationSection: some View {
        Section {
            Toggle("Enable Reminders", isOn: Binding(
                get: { preferences.notificationsEnabled },
                set: { newValue in
                    preferences.notificationsEnabled = newValue
                    updateNotifications()
                }
            ))

            if preferences.notificationsEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: Binding(
                        get: {
                            var components = DateComponents()
                            components.hour = preferences.primaryNotificationHour
                            components.minute = preferences.primaryNotificationMinute
                            return Calendar.current.date(from: components) ?? Date()
                        },
                        set: { newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            preferences.primaryNotificationHour = components.hour ?? 9
                            preferences.primaryNotificationMinute = components.minute ?? 0
                            updateNotifications()
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )

                Toggle("Weekly Reminders", isOn: Binding(
                    get: { preferences.weeklyRemindersEnabled },
                    set: { newValue in
                        preferences.weeklyRemindersEnabled = newValue
                        updateNotifications()
                    }
                ))

                if storeManager.isPremium {
                    Toggle("Evening Nudge", isOn: Binding(
                        get: { preferences.secondaryNotificationHour != nil },
                        set: { newValue in
                            if newValue {
                                preferences.secondaryNotificationHour = 20
                                preferences.secondaryNotificationMinute = 0
                            } else {
                                preferences.secondaryNotificationHour = nil
                                preferences.secondaryNotificationMinute = nil
                            }
                            updateNotifications()
                        }
                    ))

                    if preferences.secondaryNotificationHour != nil {
                        DatePicker(
                            "Evening Time",
                            selection: Binding(
                                get: {
                                    var components = DateComponents()
                                    components.hour = preferences.secondaryNotificationHour ?? 20
                                    components.minute = preferences.secondaryNotificationMinute ?? 0
                                    return Calendar.current.date(from: components) ?? Date()
                                },
                                set: { newDate in
                                    let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                                    preferences.secondaryNotificationHour = components.hour ?? 20
                                    preferences.secondaryNotificationMinute = components.minute ?? 0
                                    updateNotifications()
                                }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                    }
                } else {
                    HStack {
                        Text("Evening Nudge")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Premium") {
                            showingPaywall = true
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }
                }

                if !notificationManager.isAuthorized {
                    Button("Enable Notifications in Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .foregroundStyle(.orange)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            if !notificationManager.isAuthorized {
                Text("Notifications are disabled. Enable them in Settings to receive reminders.")
            }
        }
    }

    // MARK: - Goals Section
    @ViewBuilder
    private var goalsSection: some View {
        Section {
            ForEach(goals) { goal in
                HStack {
                    if let icon = goal.icon {
                        Text(icon)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(goal.name)
                            .fontWeight(.medium)

                        Text("\(Int(goal.progress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { goal.isActive },
                        set: { newValue in
                            goal.isActive = newValue
                            try? modelContext.save()
                        }
                    ))
                    .labelsHidden()
                }
            }
            .onDelete(perform: deleteGoals)
        } header: {
            Text("Goals")
        } footer: {
            Text("Toggle goals on/off or swipe to delete")
        }
    }

    // MARK: - About Section
    @ViewBuilder
    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://savestreak.com/privacy")!) {
                HStack {
                    Text("Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }

            Link(destination: URL(string: "https://savestreak.com/terms")!) {
                HStack {
                    Text("Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers
    private func updateNotifications() {
        let activeGoal = goals.first { $0.isActive }
        notificationManager.updateNotifications(preferences: preferences, activeGoal: activeGoal)

        try? modelContext.save()
    }

    private func deleteGoals(at offsets: IndexSet) {
        for index in offsets {
            let goal = goals[index]
            modelContext.delete(goal)
        }

        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .modelContainer(for: [SavingsGoal.self, SaveEntry.self, UserPreferences.self])
}
