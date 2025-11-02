//
//  HistoryView.swift
//  SaveStreak
//
//  Created by Claude Code
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    let goal: SavingsGoal

    @Environment(\.modelContext) private var modelContext

    private var sortedEntries: [SaveEntry] {
        goal.entries.sorted { $0.date > $1.date }
    }

    private var groupedByMonth: [(key: String, value: [SaveEntry])] {
        let grouped = Dictionary(grouping: sortedEntries) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: entry.date)
        }

        return grouped.sorted { first, second in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            guard let date1 = formatter.date(from: first.key),
                  let date2 = formatter.date(from: second.key) else {
                return false
            }
            return date1 > date2
        }
    }

    var body: some View {
        List {
            // Summary Section
            Section {
                VStack(spacing: 16) {
                    statRow(label: "Total Saved", value: formatCurrency(goal.totalSaved))
                    statRow(label: "Total Saves", value: "\(goal.entries.count)")
                    statRow(label: "Average Save", value: formatCurrency(averageSave))
                }
                .padding(.vertical, 8)
            }

            // Grouped Entries
            if sortedEntries.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("No saves yet")
                            .font(.headline)

                        Text("Your save history will appear here")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                ForEach(groupedByMonth, id: \.key) { month, entries in
                    Section(header: Text(month)) {
                        ForEach(entries) { entry in
                            entryRow(entry)
                        }
                        .onDelete { indexSet in
                            deleteEntries(at: indexSet, from: entries)
                        }
                    }
                }
            }
        }
        .navigationTitle("Save History")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Entry Row
    @ViewBuilder
    private func entryRow(_ entry: SaveEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatCurrency(entry.amount))
                    .font(.headline)

                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .italic()
                }
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Stat Row
    @ViewBuilder
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Helpers
    private var averageSave: Double {
        guard !goal.entries.isEmpty else { return 0 }
        return goal.totalSaved / Double(goal.entries.count)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }

    private func deleteEntries(at offsets: IndexSet, from entries: [SaveEntry]) {
        for index in offsets {
            let entry = entries[index]
            modelContext.delete(entry)
        }

        try? modelContext.save()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavingsGoal.self, SaveEntry.self, configurations: config)

    let goal = SavingsGoal(
        name: "Vacation Fund",
        targetAmountCents: 100000,
        deadline: Date().addingTimeInterval(2592000),
        savingsTargetCents: 500,
        isDaily: true,
        icon: "🏖️"
    )

    container.mainContext.insert(goal)

    return NavigationStack {
        HistoryView(goal: goal)
    }
    .modelContainer(container)
}
