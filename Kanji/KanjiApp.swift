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
    let modelContainer: ModelContainer
    @StateObject private var dataManager = DataManager.shared
    
    init() {
        do {
            // Daftarkan semua model SwiftData Anda di sini
            modelContainer = try ModelContainer(for: KanjiSet.self,
                                                Kanji.self,
                                                FlashCardSessionModels.self,
                                                QuizSessionModels.self,
                                                IndexOrderModels.self)
            print("✅ ModelContainer berhasil diinisialisasi.")
        } catch {
            fatalError("❌ Gagal menginisialisasi ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .onAppear {
                    Task {
                        await MainActor.run {
                            print("ℹ️ ContentView.onAppear: Memeriksa dan mengimpor data...")
                            dataManager.importDataIfNeeded(modelContext: modelContainer.mainContext)
                        }
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
