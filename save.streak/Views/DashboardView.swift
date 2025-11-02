//
//  DashboardView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SavingsGoal> { $0.isActive }, sort: \SavingsGoal.createdAt)
    private var activeGoals: [SavingsGoal]

    @State private var viewModel: DashboardViewModel?
    @State private var showingAddAmount = false
    @State private var customAmount = ""
    @State private var showingGoalSetup = false
    @State private var showingAICoach = false
    @State private var dailyTip: String?
    @State private var isLoadingTip = false

    @Query private var userPreferences: [UserPreferences]

    private var preferences: UserPreferences? {
        userPreferences.first
    }

    private var shouldShowAIFeatures: Bool {
        // AI now available for ALL users (free tier has limits)
        (preferences?.aiTipsEnabled ?? false) && AIService.shared.hasAPIKey
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let goal = activeGoals.first {
                    mainContent(for: goal)
                } else {
                    emptyState
                }
            }
            .navigationTitle("SaveStreak")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingGoalSetup) {
                GoalSetupView()
            }
            .sheet(isPresented: $showingAddAmount) {
                if let goal = activeGoals.first {
                    addSaveSheet(for: goal)
                }
            }
            .sheet(isPresented: $showingAICoach) {
                AICoachView()
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = DashboardViewModel(modelContext: modelContext)
                }
                loadDailyTipIfNeeded()
            }
        }
    }

    // MARK: - Main Content
    @ViewBuilder
    private func mainContent(for goal: SavingsGoal) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Goal Header
                goalHeader(for: goal)

                // Streak Display
                streakCard(for: goal)

                // Progress Section
                progressSection(for: goal)

                // AI Daily Tip (Premium)
                if shouldShowAIFeatures {
                    aiTipCard(for: goal)
                }

                // Quick Save Button
                quickSaveButton(for: goal)

                // Stats Overview
                statsSection(for: goal)

                // Recent Activity
                recentActivitySection(for: goal)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Goal Header
    @ViewBuilder
    private func goalHeader(for goal: SavingsGoal) -> some View {
        VStack(spacing: 8) {
            if let icon = goal.icon {
                Text(icon)
                    .font(.system(size: 50))
            }

            Text(goal.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel?.getMotivationalMessage(for: goal) ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Streak Card
    @ViewBuilder
    private func streakCard(for goal: SavingsGoal) -> some View {
        VStack(spacing: 12) {
            Text(StreakCalculator.streakMessage(for: goal))
                .font(.title)
                .fontWeight(.bold)

            if goal.currentStreak > 0 {
                HStack(spacing: 4) {
                    ForEach(0..<min(goal.currentStreak, 10), id: \.self) { _ in
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                    }
                    if goal.currentStreak > 10 {
                        Text("+\(goal.currentStreak - 10)")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            if StreakCalculator.isStreakAtRisk(for: goal) {
                Text("⚠️ Log today's save to keep your streak!")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Progress Section
    @ViewBuilder
    private func progressSection(for goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(goal.progress * 100))%")
                    .font(.headline)
                    .foregroundStyle(.green)
            }

            ProgressView(value: goal.progress)
                .tint(.green)
                .scaleEffect(y: 2)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Saved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel?.formatCurrency(goal.totalSaved) ?? "$0")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Goal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel?.formatCurrency(goal.targetAmount) ?? "$0")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }

            Divider()

            HStack {
                Label("\(goal.daysRemaining) days left", systemImage: "calendar")
                Spacer()
                Label("\(StreakCalculator.savesRemaining(for: goal)) saves to go", systemImage: "target")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Quick Save Button
    @ViewBuilder
    private func quickSaveButton(for goal: SavingsGoal) -> some View {
        VStack(spacing: 12) {
            Button(action: {
                viewModel?.quickLogSave(for: goal)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                    Text("Log \(viewModel?.formatCurrency(goal.savingsTarget) ?? "$0") Save")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .foregroundStyle(.white)
                .cornerRadius(16)
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            Button(action: {
                showingAddAmount = true
            }) {
                Text("Log Different Amount")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
        }
    }

    // MARK: - Stats Section
    @ViewBuilder
    private func statsSection(for goal: SavingsGoal) -> some View {
        HStack(spacing: 16) {
            statCard(
                title: "Current Streak",
                value: "\(goal.currentStreak)",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                title: "Best Streak",
                value: "\(goal.longestStreak)",
                icon: "trophy.fill",
                color: .yellow
            )

            statCard(
                title: "Total Saves",
                value: "\(goal.entries.count)",
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }

    @ViewBuilder
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Recent Activity
    @ViewBuilder
    private func recentActivitySection(for goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: HistoryView(goal: goal)) {
                    Text("View All")
                        .font(.subheadline)
                }
            }

            let recentEntries = viewModel?.getRecentHistory(for: goal).prefix(5) ?? []

            if recentEntries.isEmpty {
                Text("No saves yet. Start your streak today!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(Array(recentEntries), id: \.id) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel?.formatCurrency(entry.amount) ?? "$0")
                                .font(.headline)
                            Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)

                    if entry.id != recentEntries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Empty State
    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "target")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("No Active Goals")
                .font(.title2)
                .fontWeight(.bold)

            Text("Create your first savings goal to start building your streak!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button(action: {
                showingGoalSetup = true
            }) {
                Text("Create Goal")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top)
        }
    }

    // MARK: - Add Save Sheet
    @ViewBuilder
    private func addSaveSheet(for goal: SavingsGoal) -> some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Enter amount", text: $customAmount)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button("Log Save") {
                        if let amount = Double(customAmount), amount > 0 {
                            viewModel?.logSave(amount: amount, for: goal)
                            customAmount = ""
                            showingAddAmount = false
                        }
                    }
                    .disabled(Double(customAmount) ?? 0 <= 0)
                }
            }
            .navigationTitle("Log Save")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        customAmount = ""
                        showingAddAmount = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - AI Tip Card
    @ViewBuilder
    private func aiTipCard(for goal: SavingsGoal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                Text("AI Tip of the Day")
                    .font(.headline)
                Spacer()
                Button(action: { showingAICoach = true }) {
                    Image(systemName: "message.fill")
                        .foregroundStyle(.purple)
                }
            }

            if isLoadingTip {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            } else if let tip = dailyTip {
                Text(tip)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: {
                    Task {
                        await loadNewTip(for: goal)
                    }
                }) {
                    Text("Get New Tip")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            } else {
                VStack(spacing: 8) {
                    Text("Get your personalized saving tip!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Button(action: {
                        Task {
                            await loadNewTip(for: goal)
                        }
                    }) {
                        Text("Generate Tip")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Functions
    private func loadDailyTipIfNeeded() {
        guard shouldShowAIFeatures,
              let goal = activeGoals.first,
              let prefs = preferences else {
            return
        }

        // Check if we already have today's tip
        if let lastTipDate = prefs.lastTipDate,
           Calendar.current.isDateInToday(lastTipDate),
           let tip = prefs.lastDailyTip {
            dailyTip = tip
            return
        }

        // Load new tip for today
        Task {
            await loadNewTip(for: goal)
        }
    }

    private func loadNewTip(for goal: SavingsGoal) async {
        isLoadingTip = true
        defer { isLoadingTip = false }

        do {
            let tipGenerator = TipGenerator()
            let tip = try await tipGenerator.generateDailyTip(for: goal)

            dailyTip = tip

            // Save to preferences
            if let prefs = preferences {
                prefs.lastDailyTip = tip
                prefs.lastTipDate = Date()
                try? modelContext.save()
            }
        } catch {
            print("Error generating tip: \(error)")
            dailyTip = "💡 Every small save counts! Keep up your streak!"
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [SavingsGoal.self, SaveEntry.self, UserPreferences.self])
}
