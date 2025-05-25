//
//  KanjiSetFlipCardView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

struct KanjiSetFlipCardView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    @Query private var kanjiSets: [KanjiSet]
    
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
                        KanjiSetFlipCardRow(set: set)
                    }
                }
            }
        }
        .navigationTitle("Kanji Flash Card Sets")
    }
}

struct KanjiSetFlipCardRow: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Properties
    let set: KanjiSet
    
    // State
    @State private var session: FlashCardSessionModels?
    
    var body: some View {
        NavigationLink(destination: FlashCardSetupView(kanjiSet: set, onDismiss: { dismiss() })) {
            VStack(alignment: .leading) {
                HStack {
                    Text(set.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("\(set.items.count) cards")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let session = session, session.completionPercentage > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        // Progress bar
                        ProgressView(value: session.completionPercentage)
                            .tint(.green)
                            .frame(height: 6)
                        
                        // Progress details
                        HStack {
                            Text("\(Int(session.completionPercentage * 100))% complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("Last used \(FlipcardSessionManager.shared.formatLastAccessDate(session.lastAccessDate))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.vertical, 4)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadSession()
        }
    }
    
    // Load session data for this set
    private func loadSession() {
        // Get the set ID from the session manager
        let setId = FlipcardSessionManager.shared.generateSetId(for: set)
        
        // Fetch session for this set ID
        let predicate = #Predicate<FlashCardSessionModels> { session in
            session.setId == setId
        }
        let descriptor = FetchDescriptor<FlashCardSessionModels>(predicate: predicate)
        
        do {
            let existingSessions = try modelContext.fetch(descriptor)
            if let existingSession = existingSessions.first {
                session = existingSession
            }
        } catch {
            print("Error fetching session for set \(setId): \(error)")
        }
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
        KanjiSetFlipCardView()
    }
    .modelContainer(container)
}
