//
//  DataManager.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import Foundation
import SwiftData

class DataManager {
    static let shared = DataManager()
    
    private init() {}
    
    // Data file structure
    let kanjiFilesInfo: [KanjiFileInfo] = [
        KanjiFileInfo(level: "N5", files: ["kata_kerja_n5.json", "kata_sifat_na_n5.json", "kata_sifat_i_n5.json", "kata_benda_n5.json"]),
        KanjiFileInfo(level: "N4", files: ["kata_kerja_n4.json", "kata_sifat_na_n4.json", "kata_sifat_i_n4.json", "kata_benda_n4.json"]),
        KanjiFileInfo(level: "N3", files: ["kata_kerja_n3.json", "kata_benda_n3_i.json", "kata_benda_n3_ii.json"]),
        KanjiFileInfo(level: "Dummy", files: ["test_soal_3"])
    ]
    
    // Load JSON data from a file
    func loadJSON(from filename: String) -> [KanjiJSONData]? {
        guard let fileURL = Bundle.main.url(forResource: filename.replacingOccurrences(of: ".json", with: ""), withExtension: "json") else {
            print("Could not find \(filename) in bundle ")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([KanjiJSONData].self, from: data)
            return jsonData
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
    
    // Check if data already exists in the database
    func doesDataExist(forLevel level: String, fileName: String, modelContext: ModelContext) -> Bool {
        // Create a predicate to search for the specific set
        let setName = fileName.replacingOccurrences(of: ".json", with: "")
        let predicate = #Predicate<KanjiSet> { set in
            set.level == level && set.name == setName
        }
        let descriptor = FetchDescriptor<KanjiSet>(predicate: predicate)
        
        do {
            let existingSets = try modelContext.fetch(descriptor)
            return !existingSets.isEmpty
        } catch {
            print("Error checking for existing data: \(error)")
            return false
        }
    }
    
    // Import data from all JSON files if needed
    func importDataIfNeeded(modelContext: ModelContext) {
        for levelInfo in kanjiFilesInfo {
            for fileName in levelInfo.files {
                if !doesDataExist(forLevel: levelInfo.level, fileName: fileName, modelContext: modelContext) {
                    importDataFromFile(level: levelInfo.level, fileName: fileName, modelContext: modelContext)
                } else {
                    print("Data for \(levelInfo.level) - \(fileName) already exists, skipping import")
                }
            }
        }
    }
    
    // Import data from a specific file
    private func importDataFromFile(level: String, fileName: String, modelContext: ModelContext) {
        print("Importing data for \(level) - \(fileName)")
        
        guard let jsonData = loadJSON(from: fileName) else {
            print("Failed to load JSON data from \(fileName)")
            return
        }
        
        // Create a new KanjiSet
        let setName = fileName.replacingOccurrences(of: ".json", with: "")
        let kanjiSet = KanjiSet(level: level, name: setName)
        
        // Add KanjiCards to the set
        for item in jsonData {
            let kanjiCard = Kanji(
                id: UUID(),
                kanji: item.questionText,
                reading: item.option1,
                meaning: item.answerExplanation
            )
            kanjiSet.items.append(kanjiCard)
        }
        
        // Save to the database
        modelContext.insert(kanjiSet)
        
        do {
            try modelContext.save()
            print("Successfully imported \(jsonData.count) cards for \(level) - \(fileName)")
        } catch {
            print("Error saving data: \(error)")
        }
    }
}
