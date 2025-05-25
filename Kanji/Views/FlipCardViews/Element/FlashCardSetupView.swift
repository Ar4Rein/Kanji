//
//  FlashcardDeckView.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import SwiftUI
import SwiftData

struct FlashCardSetupView: View {
    var kanjiSet: KanjiSet
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    // cardBackground tidak digunakan, bisa dihapus jika tidak ada rencana penggunaan
    // @State private var cardBackground = Color.white
    @State private var showingProgressAlert = false // Mengganti nama dari showingProgress untuk lebih jelas
    @State private var shuffledCards: [Kanji] = []
    @State private var currentSession: FlashCardSessionModels?
    // isFirstLoad tidak digunakan secara aktif, bisa dihapus jika tidak ada logika khusus
    // @State private var isFirstLoad = true
    @State private var animation: Animation = .interactiveSpring() // Menggunakan interactiveSpring untuk feel lebih baik
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss // Untuk kembali jika set kosong

    var onDismiss: () -> Void
    
    // Helper untuk lebar progress bar
    func progressWidth(currentIndex: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        // Pastikan currentIndex tidak melebihi total - 1 untuk kalkulasi progress
        let currentCardNumber = min(currentIndex + 1, total)
        return CGFloat(currentCardNumber) / CGFloat(total) * (UIScreen.main.bounds.width * 0.8)
    }
    
    var body: some View {
        VStack {
            if shuffledCards.isEmpty {
                ContentUnavailableView {
                    Label("Tidak Ada Kartu", systemImage: "square.stack.3d.up.trianglebadge.exclamationmark")
                } description: {
                    Text("Set Kanji ini tidak memiliki kartu untuk ditampilkan.")
                }
                .onAppear {
                    // Jika set benar-benar kosong, mungkin ingin langsung kembali
                    // atau menampilkan pesan ini secara permanen.
                    // Untuk contoh ini, kita biarkan tampil.
                    print("Kanji set '\(kanjiSet.name)' is empty or cards failed to load.")
                }
            } else {
                // Card counter with session info
                HStack {
                    Text("\(min(currentIndex + 1, shuffledCards.count)) / \(shuffledCards.count)")
                        .font(.headline)
                    
                    if let session = currentSession, session.hasOrderSaved {
                        Text("• Melanjutkan sesi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical)
                
                // Progress indicator
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .frame(height: 8)
                        .foregroundStyle(.gray.opacity(0.3))
                    
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: progressWidth(currentIndex: currentIndex, total: shuffledCards.count), height: 8)
                        .foregroundStyle(.green)
                        .animation(animation, value: currentIndex) // Animasikan perubahan progress
                }
                .frame(width: UIScreen.main.bounds.width * 0.8)
                .padding(.bottom)
                
                // Card deck
                ZStack {
                    // Menampilkan beberapa kartu untuk efek tumpukan
                    ForEach(Array(shuffledCards.enumerated().reversed()), id: \.element.id) { index, card in
                        // Hanya render kartu yang terlihat dan beberapa di belakangnya
                        if abs(currentIndex - index) < 3 {
                             FlashCardComponentView(card: card)
                                .scaleEffect(getScale(for: index))
                                .offset(x: getOffset(for: index).width, y: getOffset(for: index).height)
                                .zIndex(Double(shuffledCards.count - index)) // Kartu terdepan Z-index tertinggi
                                .opacity(getOpacity(for: index))
                                .allowsHitTesting(index == currentIndex) // Hanya kartu terdepan yang bisa di-drag
                                .animation(animation, value: currentIndex) // Animasikan transisi kartu
                                .animation(animation, value: offset)
                        }
                    }
                }
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            if currentIndex < shuffledCards.count { // Pastikan kartu masih ada
                                offset = gesture.translation
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(animation) {
                                if offset.width < -100 { // Swipe ke kiri (kartu berikutnya)
                                    if currentIndex < shuffledCards.count - 1 {
                                        currentIndex += 1
                                        updateSession()
                                    } else if currentIndex == shuffledCards.count - 1 {
                                        // Kartu terakhir, sudah diswipe
                                        showingProgressAlert = true
                                        updateSession() // Update sesi untuk kartu terakhir
                                    }
                                } else if offset.width > 100 && currentIndex > 0 { // Swipe ke kanan (kartu sebelumnya)
                                    currentIndex -= 1
                                    updateSession()
                                }
                                offset = .zero // Reset offset setelah swipe
                            }
                        }
                )
                .padding(.vertical)
            }
        }
        .navigationTitle(kanjiSet.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        
                    } label: {
                        
                    }

                    if !shuffledCards.isEmpty {
                        Button {
                            resetToFirstCard()
                        } label: {
                            Label("Ulangi dari Awal", systemImage: "arrow.counterclockwise")
                        }
                        
                        Button {
                           handleShuffleCards()
                        } label: {
                            Label("Acak Kartu", systemImage: "shuffle")
                        }
                        
                        Button(role: .destructive) {
                           handleClearProgress()
                        } label: {
                            Label("Hapus Progres Set Ini", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Set Selesai!", isPresented: $showingProgressAlert) {
            Button("Lanjutkan Belajar") {
                showingProgressAlert = false
                // Bisa tambahkan opsi untuk ke set berikutnya atau kembali
                dismiss()
            }
            Button("Ulangi Set Ini", role: .destructive) {
                showingProgressAlert = false
                handleClearProgress() // Membersihkan progres dan memulai ulang
                resetToFirstCard()    // Pindah ke kartu pertama setelah diacak ulang
            }
        } message: {
            Text("Anda telah mempelajari semua \(shuffledCards.count) kartu di set ini.")
        }
        .onAppear {
            // Pastikan set memiliki item sebelum load session
            guard !kanjiSet.items.isEmpty else {
                print("KanjiSet items are empty on appear for \(kanjiSet.name). No session will be loaded.")
                shuffledCards = [] // Pastikan shuffledCards kosong
                return
            }
            loadSession()
        }
        .onDisappear {
            // Hanya update dan save order jika ada kartu dan sesi
            if let session = currentSession, !shuffledCards.isEmpty {
                updateSession() // Update sesi terakhir sebelum keluar
                FlipcardSessionManager.shared.saveCardOrder(
                    sessionId: session.setId,
                    cards: shuffledCards,
                    modelContext: modelContext
                )
            }
        }
    }

    // MARK: - Helper UI Functions for Card Stack
    private func getScale(for index: Int) -> CGFloat {
        if index == currentIndex {
            return 1.0
        } else if index == currentIndex + 1 || index == currentIndex - 1 {
            return 0.9
        }
        return 0.8
    }

    private func getOffset(for index: Int) -> CGSize {
        if index < currentIndex { // Kartu yang sudah dilewati (di belakang tumpukan kiri)
            return CGSize(width: -500, height: 0) // Jauhkan dari layar
        } else if index == currentIndex { // Kartu aktif
            return offset // Offset dari drag gesture
        } else if index == currentIndex + 1 { // Kartu berikutnya yang terlihat sedikit
            return CGSize(width: 0, height: 20) // Sedikit di bawah dan di tengah
        }
        // Kartu lain di tumpukan (lebih jauh di belakang)
        return CGSize(width: 0, height: CGFloat(index - currentIndex) * 10 + 20)
    }
    
    private func getOpacity(for index: Int) -> Double {
        if index < currentIndex { // Kartu yang sudah dilewati
            return 0.0
        } else if index == currentIndex || index == currentIndex + 1 { // Kartu aktif dan berikutnya
            return 1.0
        }
        // Kartu lain di tumpukan (lebih jauh di belakang), buat sedikit transparan
        return 0.5
    }

    // MARK: - Action Handlers
    private func goNext() {
        withAnimation(animation) {
            if currentIndex < shuffledCards.count - 1 {
                currentIndex += 1
                updateSession()
            } else if currentIndex == shuffledCards.count - 1 {
                showingProgressAlert = true
                updateSession()
            }
        }
    }

    private func goPrevious() {
        withAnimation(animation) {
            if currentIndex > 0 {
                currentIndex -= 1
                updateSession()
            }
        }
    }
    
    private func resetToFirstCard() {
        withAnimation(animation) {
            currentIndex = 0
            updateSession() // Update sesi bahwa kita kembali ke kartu pertama
            // Tidak perlu save order di sini karena urutannya tidak berubah
        }
    }

    private func handleShuffleCards() {
        withAnimation(animation) {
            shuffleCardsAndUpdateSession()
            // Save order baru setelah diacak
            if let session = currentSession, !shuffledCards.isEmpty {
                FlipcardSessionManager.shared.saveCardOrder(
                    sessionId: session.setId,
                    cards: shuffledCards,
                    modelContext: modelContext
                )
            }
        }
    }

    private func handleClearProgress() {
        withAnimation(animation) {
            clearSessionData() // Hapus data sesi
            shuffleCardsAndUpdateSession() // Acak ulang kartu dan reset index
            // Save order baru (karena setelah clear, sesi akan anggap order baru)
            if let session = currentSession, !shuffledCards.isEmpty {
                 FlipcardSessionManager.shared.saveCardOrder(
                    sessionId: session.setId,
                    cards: shuffledCards,
                    modelContext: modelContext
                )
            }
        }
    }
    
    // MARK: - Session and Card Logic
    private func loadSession() {
        // Pastikan kanjiSet.items tidak kosong sebelum melanjutkan
        guard !kanjiSet.items.isEmpty else {
            shuffledCards = []
            print("Cannot load session: KanjiSet items are empty for \(kanjiSet.name).")
            // Pertimbangkan untuk dismiss view jika tidak ada kartu
            // dismiss()
            return
        }

        currentSession = FlipcardSessionManager.shared.getOrCreateSession(for: kanjiSet, modelContext: modelContext)
        
        guard let session = currentSession else {
            // Jika sesi tidak bisa dibuat/diambil, acak kartu default
            shuffleCardsOnly()
            currentIndex = 0
            print("Warning: Could not get or create session. Defaulting to new shuffle.")
            return
        }
        
        // Coba load order kartu yang tersimpan
        if session.hasOrderSaved,
           let savedOrderedCards = FlipcardSessionManager.shared.loadCardOrder(
               sessionId: session.setId,
               availableCards: kanjiSet.items, // kanjiSet.items adalah sumber kebenaran kartu yang ada
               modelContext: modelContext),
           !savedOrderedCards.isEmpty { // Pastikan kartu yang di-load tidak kosong
            
            shuffledCards = savedOrderedCards
            // Pastikan currentIndex valid dan dalam batas
            currentIndex = min(max(0, session.lastViewedCardIndex), shuffledCards.count - 1)
            print("Restored session for \(session.setId) with \(shuffledCards.count) cards at index \(currentIndex).")
        } else {
            // Jika tidak ada order tersimpan, gagal load, atau order kosong, acak kartu
            shuffleCardsOnly()
            currentIndex = 0 // Mulai dari awal untuk tumpukan baru
            // Jika sesi ada tapi order tidak ada/gagal, dan ada lastViewedCardIndex, itu mungkin tidak relevan lagi dengan urutan baru.
            // Jadi, lebih aman memulai dari 0.
            // Tandai bahwa order (yang baru diacak) perlu disimpan saat keluar atau saat shuffle berikutnya.
            // FlipcardSessionManager.shared.updateSessionOrderFlag(sessionId: session.setId, hasOrder: false, modelContext: modelContext)
            // Tidak perlu update flag di sini, saveCardOrder akan menanganinya.
            print("No saved order or failed to load for \(session.setId). Shuffled \(kanjiSet.items.count) cards. Starting at index 0.")
        }
        // isFirstLoad = false // Tidak digunakan lagi
    }
    
    private func updateSession() {
        guard let session = currentSession, !shuffledCards.isEmpty else { return }
        // Pastikan currentIndex valid sebelum update
        let validCurrentIndex = min(max(0, currentIndex), shuffledCards.count - 1)

        FlipcardSessionManager.shared.updateSession(
            session: session,
            currentIndex: validCurrentIndex, // Gunakan index yang sudah divalidasi
            totalCards: shuffledCards.count,
            modelContext: modelContext
        )
    }
    
    // Hanya mengacak kartu tanpa update sesi terkait progres
    private func shuffleCardsOnly() {
        guard !kanjiSet.items.isEmpty else {
            shuffledCards = []
            return
        }
        shuffledCards = kanjiSet.items.shuffled()
    }

    // Mengacak kartu dan mereset progres sesi ke awal
    private func shuffleCardsAndUpdateSession() {
        shuffleCardsOnly()
        currentIndex = 0 // Selalu reset ke 0 setelah shuffle baru
        if currentSession != nil {
            updateSession() // Update sesi dengan index baru (0) dan total kartu
        }
    }
    
    private func clearSessionData() {
        FlipcardSessionManager.shared.clearSession(for: kanjiSet, modelContext: modelContext)
        // Setelah clear, dapatkan sesi baru (yang bersih)
        currentSession = FlipcardSessionManager.shared.getOrCreateSession(for: kanjiSet, modelContext: modelContext)
    }
}
