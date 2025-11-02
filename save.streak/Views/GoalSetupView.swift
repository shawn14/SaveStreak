//
//  GoalSetupView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct GoalSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var existingGoals: [SavingsGoal]
    @Query private var userPreferences: [UserPreferences]

    @StateObject private var storeManager = StoreManager.shared

    @State private var goalName = ""
    @State private var targetAmount = ""
    @State private var dailyTarget = ""
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var isDaily = true
    @State private var selectedIcon = "💰"
    @State private var showingPaywall = false

    private let availableIcons = ["💰", "🏖️", "🏠", "🚗", "🎓", "💍", "🎮", "📱", "✈️", "🎯"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal Details") {
                    TextField("Goal Name", text: $goalName)
                        .autocorrectionDisabled()

                    HStack {
                        Text("Icon")
                        Spacer()
                        Picker("Icon", selection: $selectedIcon) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Text(icon).tag(icon)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Target Amount") {
                    HStack {
                        Text("$")
                        TextField("500", text: $targetAmount)
                            .keyboardType(.decimalPad)
                    }

                    DatePicker("Deadline", selection: $deadline, in: Date()..., displayedComponents: .date)
                }

                Section("Savings Frequency") {
                    Picker("Frequency", selection: $isDaily) {
                        Text("Daily").tag(true)
                        Text("Weekly").tag(false)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("$")
                        TextField(isDaily ? "5 per day" : "35 per week", text: $dailyTarget)
                            .keyboardType(.decimalPad)
                        Text(isDaily ? "/ day" : "/ week")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    if let target = Double(targetAmount), let daily = Double(dailyTarget), target > 0, daily > 0 {
                        let estimatedSaves = Int(ceil(target / daily))
                        let estimatedDays = isDaily ? estimatedSaves : estimatedSaves * 7

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Estimated Timeline")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("You'll need approximately \(estimatedSaves) saves (\(estimatedDays) days)")
                                .font(.caption)

                            if let targetDate = Calendar.current.date(byAdding: .day, value: estimatedDays, to: Date()) {
                                if targetDate > deadline {
                                    Label("Your deadline might be too soon", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                } else {
                                    Label("You're on track to finish early!", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    }
                }

                Section {
                    Button(action: createGoal) {
                        Text("Create Goal")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("New Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private var isFormValid: Bool {
        !goalName.isEmpty &&
        (Double(targetAmount) ?? 0) > 0 &&
        (Double(dailyTarget) ?? 0) > 0
    }

    private var isPremium: Bool {
        userPreferences.first?.isPremium ?? false
    }

    private func createGoal() {
        // Check if free user is trying to create second goal
        let activeGoalCount = existingGoals.filter { $0.isActive }.count

        if !isPremium && activeGoalCount >= 1 {
            // Show paywall
            showingPaywall = true
            return
        }

        guard let targetAmountDouble = Double(targetAmount),
              let dailyTargetDouble = Double(dailyTarget) else {
            return
        }

        // Convert to cents
        let targetCents = Int(targetAmountDouble * 100)
        let dailyTargetCents = Int(dailyTargetDouble * 100)

        // Create new goal
        let newGoal = SavingsGoal(
            name: goalName,
            targetAmountCents: targetCents,
            deadline: deadline,
            savingsTargetCents: dailyTargetCents,
            isDaily: isDaily,
            icon: selectedIcon
        )

        modelContext.insert(newGoal)

        do {
            try modelContext.save()

            // Update notifications
            let notificationManager = NotificationManager.shared
            if let preferences = userPreferences.first {
                notificationManager.updateNotifications(preferences: preferences, activeGoal: newGoal)
            }

            dismiss()
        } catch {
            print("Error saving goal: \(error)")
        }
    }
}

#Preview {
    GoalSetupView()
        .modelContainer(for: [SavingsGoal.self, SaveEntry.self, UserPreferences.self])
}
