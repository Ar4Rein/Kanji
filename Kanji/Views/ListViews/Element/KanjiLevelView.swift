//
//  KanjiLevelView.swift
//  ListOfKanji
//
//  Created by Muhammad Ardiansyah on 23/05/25.
//


import SwiftUI
import SwiftData

struct KanjiLevelView: View {
    let level: String
    @Environment(\.modelContext) private var modelContext

    // Query untuk KanjiSet khusus level ini, diurutkan berdasarkan nama (jenis)
    @Query private var kanjiSetsForLevel: [KanjiSet]

    // State untuk filter internal di dalam tab ini
    @State private var selectedSetName: String? // Untuk filter "jenis" (nama KanjiSet)
    @State private var searchText: String = ""

    // Initializer untuk mengkonfigurasi query secara dinamis berdasarkan level
    init(level: String) {
        self.level = level
        let predicate = #Predicate<KanjiSet> { kanjiSet in
            kanjiSet.level == level
        }
        // Konfigurasi @Query dengan predicate dan sort descriptor
        self._kanjiSetsForLevel = Query(filter: predicate, sort: [SortDescriptor(\KanjiSet.name)])
    }

    // Daftar "jenis" (nama KanjiSet) yang tersedia untuk level ini
    private var availableTypes: [String] {
        // Nama sudah diurutkan oleh query. Ambil yang unik.
        Array(Set(kanjiSetsForLevel.map { $0.name })).sorted()
    }

    // Computed property untuk mendapatkan daftar Kanji yang sudah difilter
    private var filteredKanjiItems: [Kanji] {
        var items: [Kanji] = []

        // 1. Filter berdasarkan selectedSetName (jenis)
        let setsToConsider: [KanjiSet]
        if let setName = selectedSetName, !setName.isEmpty {
            setsToConsider = kanjiSetsForLevel.filter { $0.name == setName }
        } else {
            // Jika tidak ada jenis yang dipilih, ambil semua set untuk level ini
            setsToConsider = kanjiSetsForLevel
        }

        // 2. Kumpulkan item Kanji dari set yang terpilih
        for set in setsToConsider {
            items.append(contentsOf: set.items)
        }

        // 3. Filter berdasarkan searchText
        if searchText.isEmpty {
            // Urutkan berdasarkan karakter Kanji jika tidak ada pencarian
            return items.sorted { $0.kanji < $1.kanji }
        } else {
            let lowercasedSearchText = searchText.lowercased()
            return items.filter { kanji in
                kanji.kanji.lowercased().contains(lowercasedSearchText) ||
                kanji.reading.lowercased().contains(lowercasedSearchText) ||
                kanji.meaning.lowercased().contains(lowercasedSearchText)
            }.sorted { $0.kanji < $1.kanji } // Urutkan hasil pencarian
        }
    }
    
    // Fungsi untuk mempercantik nama jenis
    private func prettifyTypeName(_ name: String) -> String {
        var prettyName = name
        // Hapus "_n5", "_n4", "_n3" karena level sudah jelas dari tab
        prettyName = prettyName.replacingOccurrences(of: "_n5", with: "")
                               .replacingOccurrences(of: "_n4", with: "")
                               .replacingOccurrences(of: "_n3", with: "")
        
        prettyName = prettyName.replacingOccurrences(of: "kata_kerja", with: "Kata Kerja")
                               .replacingOccurrences(of: "kata_sifat_na", with: "Kata Sifat (な)")
                               .replacingOccurrences(of: "kata_sifat_i", with: "Kata Sifat (い)")
                               .replacingOccurrences(of: "kata_benda", with: "Kata Benda")
                               .replacingOccurrences(of: "_i", with: " I") // Untuk N3_i, N3_ii
                               .replacingOccurrences(of: "_ii", with: " II")
                               .replacingOccurrences(of: "_", with: " ") // Ganti underscore dengan spasi
                               .capitalized // Kapitalisasi setiap kata
        return prettyName.trimmingCharacters(in: .whitespacesAndNewlines)
    }


    var body: some View {
        // NavigationView memungkinkan judul dan potensi navigasi ke detail Kanji
        NavigationView {
            VStack(spacing: 0) { // Mengurangi spacing default antar elemen VStack
                // Kontrol Filter
                VStack(spacing: 10) { // VStack untuk grup filter
                    if !availableTypes.isEmpty {
                        Picker("Pilih Jenis", selection: $selectedSetName) {
                            Text("Semua Jenis").tag(String?.none) // Opsi untuk semua jenis
                            ForEach(availableTypes, id: \.self) { typeName in
                                Text(prettifyTypeName(typeName)).tag(String?(typeName))
                            }
                        }
                        .pickerStyle(.menu) // Gaya picker yang lebih kompak
                    }

                    TextField("Cari Kanji (karakter, bacaan, arti)...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal) // Padding agar tidak terlalu mepet
                }
                .padding(.vertical, 10) // Padding vertikal untuk grup filter
                .background(Color(.systemGroupedBackground).opacity(0.5)) // Sedikit bedakan background filter

                Divider()

                // Daftar Kanji
                if filteredKanjiItems.isEmpty {
                    ContentUnavailableView {
                        Label("Tidak Ada Kanji", systemImage: "doc.text.magnifyingglass")
                    } description: {
                        Text(searchText.isEmpty && selectedSetName == nil ? "Tidak ada data Kanji untuk level \(level) dengan filter ini." : "Tidak ada hasil yang cocok dengan pencarian atau filter Anda.")
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredKanjiItems) { kanji in
                        KanjiRow(kanji: kanji)
                    }
                    .listStyle(.plain) // Gaya list yang lebih sederhana
                }
            }
            .navigationTitle("Kanji Level \(level)")
            .navigationBarTitleDisplayMode(.inline) // Judul yang lebih kecil
        }
        // Penting untuk iPad agar tidak default ke split view jika ini adalah root scene tab
        // .navigationViewStyle(.stack) // Deprecated, gunakan NavigationStack jika diperlukan navigasi lebih dalam
    }
}

struct KanjiRow: View {
    let kanji: Kanji

    var body: some View {
        HStack(spacing: 15) {
            Text(kanji.kanji)
                .font(.system(size: 40)) // Ukuran font lebih besar untuk Kanji
                .frame(minWidth: 50) // Pastikan ada ruang untuk Kanji besar
            
            VStack(alignment: .leading, spacing: 4) {
                Text(kanji.reading)
                    .font(.headline)
                    .foregroundColor(.blue) // Warna untuk bacaan agar mudah dibedakan
                Text(kanji.meaning)
                    .font(.subheadline)
                    .foregroundColor(.secondary) // Warna standar untuk arti
                    .lineLimit(2) // Batasi jumlah baris jika arti terlalu panjang
            }
            Spacer() // Dorong konten ke kiri
        }
        .padding(.vertical, 8) // Padding vertikal untuk setiap baris
    }
}
