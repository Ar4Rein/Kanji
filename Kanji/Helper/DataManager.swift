//
//  DataManager.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import Foundation
import SwiftData

class DataManager {
    static let shared = DataManager() // Singleton instance.
    
    private init() {} // Private constructor.
    
    // Struktur data file JSON yang akan diimpor.
    let kanjiFilesInfo: [KanjiFileInfo] = [
        KanjiFileInfo(level: "N5", files: ["kata_kerja_n5.json", "kata_sifat_na_n5.json", "kata_sifat_i_n5.json", "kata_benda_n5.json"]),
        KanjiFileInfo(level: "N4", files: ["kata_kerja_n4.json", "kata_sifat_na_n4.json", "kata_sifat_i_n4.json", "kata_benda_n4.json"]),
        KanjiFileInfo(level: "N3", files: ["kata_kerja_n3.json", "kata_benda_n3_i.json", "kata_benda_n3_ii.json"]),
        KanjiFileInfo(level: "Dummy", files: ["test_soal_3.json"]) // Ekstensi .json sudah disiapkan
    ]
    
    // Fungsi untuk memuat file JSON dari bundle.
    func loadJSON(from filename: String) -> [KanjiJSONData]? {
        let resourceName = filename.replacingOccurrences(of: ".json", with: "")
        guard let fileURL = Bundle.main.url(forResource: resourceName, withExtension: "json") else {
            print("❌ Tidak dapat menemukan file \(filename) di dalam bundle aplikasi.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let jsonData = try decoder.decode([KanjiJSONData].self, from: data)
            return jsonData
        } catch {
            print("❌ Error saat men-decode JSON dari file \(filename): \(error)")
            return nil
        }
    }
    
    // Fungsi untuk mengecek apakah data sudah ada di database.
    func doesDataExist(forLevel level: String, fileName: String, modelContext: ModelContext) -> Bool {
        let setName = fileName.replacingOccurrences(of: ".json", with: "")
        let predicate = #Predicate<KanjiSet> { set in
            set.level == level && set.name == setName
        }
        let descriptor = FetchDescriptor<KanjiSet>(predicate: predicate)
        
        do {
            let existingSets = try modelContext.fetch(descriptor)
            return !existingSets.isEmpty
        } catch {
            print("❌ Error saat memeriksa data yang sudah ada: \(error)")
            return false
        }
    }
    
    // Fungsi utama untuk memulai proses impor data jika belum ada di database.
    func importDataIfNeeded(modelContext: ModelContext) {
        print("📥 Memulai proses pemeriksaan dan impor data...")
        for levelInfo in kanjiFilesInfo {
            for fileName in levelInfo.files {
                if !doesDataExist(forLevel: levelInfo.level, fileName: fileName, modelContext: modelContext) {
                    importDataFromFile(level: levelInfo.level, fileName: fileName, modelContext: modelContext)
                } else {
                    print("ℹ️ Data untuk \(levelInfo.level) - \(fileName) sudah ada, impor dilewati.")
                }
            }
        }
        print("✅ Proses pemeriksaan dan impor data selesai.")
    }
    
    // Fungsi untuk mengimpor data dari satu file JSON.
    private func importDataFromFile(level: String, fileName: String, modelContext: ModelContext) {
        print("📦 Mengimpor data untuk \(level) - \(fileName)...")
        
        guard let jsonDataArray = loadJSON(from: fileName) else {
            print("❌ Gagal memuat data JSON dari \(fileName). Impor dibatalkan.")
            return
        }
        
        let setName = fileName.replacingOccurrences(of: ".json", with: "")
        let newKanjiSet = KanjiSet(level: level, name: setName, items: [])
        
        var importedKanjiCount = 0
        for item in jsonDataArray {
            let kanjiItem = Kanji(
                id: UUID(),
                kanji: item.questionText,
                reading: item.option1,
                meaning: item.answerExplanation
            )
            newKanjiSet.items.append(kanjiItem)
            importedKanjiCount += 1
        }
        
        modelContext.insert(newKanjiSet)
        
        do {
            try modelContext.save()
            if importedKanjiCount > 0 {
                print("✅ Berhasil mengimpor \(importedKanjiCount) item Kanji untuk \(level) - \(setName).")
            } else {
                print("⚠️ File JSON \(fileName) kosong atau tidak ada item valid. KanjiSet tetap dibuat.")
            }
        } catch {
            print("❌ Error saat menyimpan data: \(error)")
        }
    }

    // Fungsi tambahan untuk menghapus semua data dari database (opsional tapi penting).
    func deleteAllKanjiData(modelContext: ModelContext) {
        print("🗑️ Memulai proses penghapusan semua data KanjiSet...")
        let descriptor = FetchDescriptor<KanjiSet>()
        
        do {
            let allKanjiSets = try modelContext.fetch(descriptor)
            
            if allKanjiSets.isEmpty {
                print("ℹ️ Tidak ada data KanjiSet untuk dihapus.")
                return
            }
            
            for kanjiSet in allKanjiSets {
                modelContext.delete(kanjiSet)
            }
            
            try modelContext.save()
            print("✅ Berhasil menghapus \(allKanjiSets.count) KanjiSet dan semua Kanji terkait.")
        } catch {
            print("❌ Error saat menghapus data: \(error)")
        }
    }
}

