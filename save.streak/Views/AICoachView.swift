//
//  AICoachView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct AICoachView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var goals: [SavingsGoal]
    @Query private var userPreferences: [UserPreferences]

    @StateObject private var coach = GoalCoach()
    @State private var messageText = ""
    @State private var showingPaywall = false
    @State private var showingLimitReached = false

    private var activeGoal: SavingsGoal? {
        goals.first { $0.isActive }
    }

    private var isPremium: Bool {
        userPreferences.first?.isPremium ?? false
    }

    private var preferences: UserPreferences? {
        userPreferences.first
    }

    private var canUseCoach: Bool {
        preferences?.canUseAICoach(isPremium: isPremium) ?? false
    }

    private var remainingConversations: Int? {
        preferences?.remainingAICoachConversations(isPremium: isPremium)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !AIService.shared.hasAPIKey {
                    apiKeyPrompt
                } else if !canUseCoach {
                    limitReachedPrompt
                } else {
                    chatContent
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                // Show usage counter for free users
                if !isPremium, let remaining = remainingConversations {
                    ToolbarItem(placement: .principal) {
                        HStack {
                            Text("AI Coach")
                                .font(.headline)
                            Text("(\(remaining)/3 today)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                if !coach.conversation.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            coach.clearConversation()
                        }) {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Chat Content
    @ViewBuilder
    private var chatContent: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if coach.conversation.isEmpty {
                        welcomeMessage
                        quickActions
                    } else {
                        ForEach(coach.conversation.filter { $0.role != .system }) { message in
                            MessageBubble(message: message)
                        }

                        if coach.isThinking {
                            thinkingIndicator
                        }
                    }
                }
                .padding()
            }
            .onChange(of: coach.conversation.count) { _, _ in
                if let lastMessage = coach.conversation.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }

        // Input bar
        messageInputBar
    }

    // MARK: - Welcome Message
    @ViewBuilder
    private var welcomeMessage: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.filled.head.profile")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("AI Savings Coach")
                .font(.title2)
                .fontWeight(.bold)

            Text("I'm here to help you reach your savings goals! Ask me anything about saving money, adjusting your goals, or staying motivated.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical, 32)
    }

    // MARK: - Quick Actions
    @ViewBuilder
    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Try asking:")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            VStack(spacing: 8) {
                QuickActionButton(icon: "target", text: "Am I on track?") {
                    if let goal = activeGoal {
                        Task {
                            await coach.askAboutGoal(goal, question: "Am I on track to reach my goal?")
                        }
                    }
                }

                QuickActionButton(icon: "lightbulb.fill", text: "Give me a saving tip") {
                    Task {
                        await coach.sendMessage("Give me one specific tip to save money today")
                    }
                }

                QuickActionButton(icon: "chart.line.uptrend.xyaxis", text: "How can I save more?") {
                    if let goal = activeGoal {
                        Task {
                            await coach.askAboutGoal(goal, question: "How can I save more to reach my goal faster?")
                        }
                    }
                }

                QuickActionButton(icon: "calendar", text: "Should I adjust my deadline?") {
                    if let goal = activeGoal {
                        Task {
                            await coach.getAdjustmentAdvice(for: goal)
                        }
                    }
                }
            }
        }
        .padding(.bottom)
    }

    // MARK: - Message Input Bar
    @ViewBuilder
    private var messageInputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask me anything...", text: $messageText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .disabled(coach.isThinking)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(messageText.isEmpty ? .gray : .blue)
            }
            .disabled(messageText.isEmpty || coach.isThinking)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Thinking Indicator
    @ViewBuilder
    private var thinkingIndicator: some View {
        HStack {
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(coach.isThinking ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: coach.isThinking
                        )
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(20)

            Spacer()
        }
    }

    // MARK: - Limit Reached Prompt
    @ViewBuilder
    private var limitReachedPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "clock.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Daily Limit Reached")
                .font(.title2)
                .fontWeight(.bold)

            Text("You've used all 3 free AI Coach conversations today. Come back tomorrow or upgrade to Premium for unlimited access!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                Text("Resets at midnight")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button(action: {
                    showingPaywall = true
                }) {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Upgrade for Unlimited")
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    // MARK: - API Key Prompt
    @ViewBuilder
    private var apiKeyPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text("Setup Required")
                .font(.title2)
                .fontWeight(.bold)

            Text("To use AI Coach, please add your OpenAI API key in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        let message = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }

        messageText = ""

        // Increment usage counter for free users
        if let prefs = preferences, !isPremium {
            prefs.incrementAICoachUsage()
            try? modelContext.save()
        }

        Task {
            await coach.sendMessage(message)
        }
    }
}

// MARK: - Message Bubble
struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(message.role == .user ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.role == .assistant {
                Spacer()
            }
        }
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(text)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AICoachView()
        .modelContainer(for: [SavingsGoal.self, SaveEntry.self, UserPreferences.self])
}
