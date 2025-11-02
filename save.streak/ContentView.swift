//
//  ContentView.swift
//  save.streak
//
//  Created by Shawn Carpenter on 11/1/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        DashboardView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SavingsGoal.self, SaveEntry.self, UserPreferences.self], inMemory: true)
}
