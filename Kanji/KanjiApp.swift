//
//  KanjiApp.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

@main
struct KanjiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            KanjiSet.self,
            Kanji.self,
            UserSessionCardModels.self,
            IndexOrderModels.self
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
            MainView()
        }
        .modelContainer(sharedModelContainer)
    }
}
