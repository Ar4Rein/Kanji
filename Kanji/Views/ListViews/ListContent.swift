//
//  ListContent.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 23/05/25.
//

import SwiftUI
import SwiftData

struct ListContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Mengambil semua KanjiSet dan mengurutkannya berdasarkan level, lalu nama.
    @Query(sort: [SortDescriptor(\KanjiSet.level), SortDescriptor(\KanjiSet.name)]) private var allKanjiSets: [KanjiSet]

    // Membuat daftar level unik untuk tab
    private var levels: [String] {
        // Menggunakan Set untuk mendapatkan level unik, lalu diurutkan.
        // Lebih baik mengandalkan urutan dari @Query jika memungkinkan,
        // tapi untuk daftar tab, kita perlu pastikan keunikannya.
        Array(Set(allKanjiSets.map { $0.level })).sorted()
    }

    var body: some View {
        // Tampilkan pesan jika tidak ada level (data belum dimuat atau tidak ada)
        if levels.isEmpty {
            VStack(spacing: 20) {
                Text("Tidak ada data Kanji.")
                    .font(.headline)
                Text("Silakan periksa apakah file JSON sudah ada di bundle dan coba impor ulang jika perlu.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Tombol untuk debugging (opsional)
                Button("Coba Impor Ulang Data") {
                    DataManager.shared.importDataIfNeeded(modelContext: modelContext)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Hapus Semua Data (Debug)") {
                    DataManager.shared.deleteAllKanjiData(modelContext: modelContext)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
        } else {
            // Tampilkan TabView jika ada data level
            TabView {
                ForEach(levels, id: \.self) { level in
                    KanjiLevelView(level: level)
                        .tabItem {
                            // Label untuk setiap tab
                            Label(level, systemImage: imageNameForLevel(level))
                        }
                        .tag(level) // Tag untuk identifikasi tab
                }
            }
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }

    // Fungsi helper untuk ikon tab berdasarkan level (contoh)
    private func imageNameForLevel(_ level: String) -> String {
        switch level {
        case "N5": return "5.square.fill"
        case "N4": return "4.square.fill"
        case "N3": return "3.square.fill"
        default: return "list.star"
        }
    }
}

#Preview {
    ListContentView()
}
