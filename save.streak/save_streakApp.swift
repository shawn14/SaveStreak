//
//  save_streakApp.swift
//  save.streak
//
//  Created by Shawn Carpenter on 11/1/25.
//

import SwiftUI
import SwiftData

@main
struct save_streakApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavingsGoal.self,
            SaveEntry.self,
            UserPreferences.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
