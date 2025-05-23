//
//  KanjiSetQuizView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

struct KanjiSetQuizView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Query private var kanjiSets: [KanjiSet]
    
    @State private var hideTabBar: Bool = false
    
    // Grouped kanji sets by level
    private var setsByLevel: [String: [KanjiSet]] {
        Dictionary(grouping: kanjiSets) { $0.level }
    }
    
    // Sorted levels
    private var sortedLevels: [String] {
        let levels = setsByLevel.keys.sorted { key1, key2 in
            // Custom sorting for JLPT levels (N5 to N1)
            if key1.starts(with: "N") && key2.starts(with: "N") {
                let n1 = Int(key1.dropFirst()) ?? 0
                let n2 = Int(key2.dropFirst()) ?? 0
                return n1 > n2
            }
            return key1 < key2
        }
        return levels
    }
    
    var body: some View {
        List {
            ForEach(sortedLevels, id: \.self) { level in
                Section(header: Text(level)) {
                    ForEach(setsByLevel[level] ?? [], id: \.self) { set in
                        NavigationLink(value: set) {
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(set.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(set.items.count) cards")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .navigationTitle("Kanji Quiz Sets")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: KanjiSet.self) { kanjiSet in
            // Pastikan KanjiSet yang diteruskan memiliki item sebelum memulai kuis.
            if kanjiSet.items.isEmpty {
                ContentUnavailableView("Set Kosong", systemImage: "tray.fill", description: Text("Set \"\(kanjiSet.name)\" tidak memiliki Kanji untuk dikuiskan."))
            } else {
                QuizSetupView(kanjiSet: kanjiSet)
            }
        }
    }
    
    // Ensure the data is imported when the view first appears
    private func ensureDataIsImported() {
        DataManager.shared.importDataIfNeeded(modelContext: modelContext)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KanjiSet.self, Kanji.self, FlashCardSessionModels.self, configurations: config)
    
    // Create a sample KanjiSet with cards for preview
    let exampleSet1 = KanjiSet(level: "N5", name: "Kata Kerja N5")
    exampleSet1.items = [
        Kanji(id: UUID(), kanji: "見る", reading: "みる", meaning: "to see"),
        Kanji(id: UUID(), kanji: "聞く", reading: "きく", meaning: "to hear")
    ]
    
    let exampleSet2 = KanjiSet(level: "N5", name: "Kata Benda N5")
    exampleSet2.items = [
        Kanji(id: UUID(), kanji: "犬", reading: "いぬ", meaning: "dog"),
        Kanji(id: UUID(), kanji: "猫", reading: "ねこ", meaning: "cat")
    ]
    
    let exampleSet3 = KanjiSet(level: "N4", name: "Kata Kerja N4")
    exampleSet3.items = [
        Kanji(id: UUID(), kanji: "動く", reading: "うごく", meaning: "to move"),
        Kanji(id: UUID(), kanji: "助ける", reading: "たすける", meaning: "to help")
    ]
    
    // Add sample sets to container
    let modelContext = ModelContext(container)
    modelContext.insert(exampleSet1)
    modelContext.insert(exampleSet2)
    modelContext.insert(exampleSet3)
    
    // Create a sample session
    let session = FlashCardSessionModels(setId: "N5_Kata Kerja N5", lastViewedCardIndex: 1, completionPercentage: 0.5)
    modelContext.insert(session)
    
    return NavigationStack {
        KanjiSetQuizView()
    }
    .modelContainer(container)
}
