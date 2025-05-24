//
//  FlipcardSessionManager.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 12/05/25.
//

import Foundation
import SwiftData

// Class to manage user sessions
@MainActor // <--- TAMBAHKAN INI
class FlipcardSessionManager {
    static let shared = FlipcardSessionManager()
    
    private init() {}
    
    // Generate a unique ID for a kanji set
    func generateSetId(for set: KanjiSet) -> String {
        return "\(set.level)_\(set.name)"
    }
    
    // Fetch or create a session for the given kanji set
    func getOrCreateSession(for set: KanjiSet, modelContext: ModelContext) -> FlashCardSessionModels {
        let setId = generateSetId(for: set)
        
        let predicate = #Predicate<FlashCardSessionModels> { session in
            session.setId == setId
        }
        let descriptor = FetchDescriptor<FlashCardSessionModels>(predicate: predicate)
        
        do {
            if let existingSession = try modelContext.fetch(descriptor).first {
                existingSession.lastAccessDate = Date()
                // Pertimbangkan untuk save di sini jika pembaruan lastAccessDate selalu ingin segera disimpan.
                // Namun, untuk konsistensi, save bisa ditangani oleh pemanggil atau di akhir operasi yang lebih besar.
                // if modelContext.hasChanges { try? modelContext.save() }
                return existingSession
            }
        } catch {
            print("Error fetching session: \(error)")
        }
        
        let newSession = FlashCardSessionModels(setId: setId)
        modelContext.insert(newSession)
        
        do {
            try modelContext.save() // Save saat membuat sesi baru
        } catch {
            print("Error saving new session: \(error)")
        }
        
        return newSession
    }
    
    // Update session data
    func updateSession(session: FlashCardSessionModels, currentIndex: Int, totalCards: Int, modelContext: ModelContext) {
        guard totalCards > 0 else {
            print("Error updating session: totalCards is zero.")
            return
        }
        session.lastViewedCardIndex = currentIndex
        session.completionPercentage = min(Double(currentIndex + 1) / Double(totalCards), 1.0)
        session.lastAccessDate = Date()
        
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                print("Session updated: \(session.setId), Card: \(currentIndex), Completion: \(String(format: "%.2f", session.completionPercentage * 100))%")
            } catch {
                print("Error updating session: \(error)")
            }
        }
    }
    
    // Clear session data for a set
    func clearSession(for set: KanjiSet, modelContext: ModelContext) {
        let setId = generateSetId(for: set)
        
        clearSessionWithId(setId: setId, modelContext: modelContext, shouldSave: false)
        clearCardOrder(for: setId, modelContext: modelContext, shouldSave: false)
        
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                print("Session and card order cleared for \(setId) and saved.")
            } catch {
                print("Error saving after clearing session and card order for \(setId): \(error)")
            }
        }
    }
    
    // Clear a session by its ID
    private func clearSessionWithId(setId: String, modelContext: ModelContext, shouldSave: Bool = true) {
        let predicate = #Predicate<FlashCardSessionModels> { session in
            session.setId == setId
        }
        do {
            try modelContext.delete(model: FlashCardSessionModels.self, where: predicate)
            print("Session data marked for deletion for setId: \(setId)")
            if shouldSave && modelContext.hasChanges {
                try modelContext.save()
                print("Session data cleared and saved for setId: \(setId)")
            }
        } catch {
            print("Error clearing session with ID \(setId): \(error)")
        }
    }
    
    // Clear all sessions
    func clearAllSessions(modelContext: ModelContext) {
        var allSetIds: [String] = []
        do {
            // Fetch semua sesi untuk mendapatkan setIds dan untuk dihapus
            let allSessions = try modelContext.fetch(FetchDescriptor<FlashCardSessionModels>())
            if allSessions.isEmpty {
                print("No sessions to clear.")
                return
            }
            allSetIds = allSessions.map { $0.setId }
            
            for session in allSessions {
                modelContext.delete(session)
            }
            print("All session models marked for deletion.")

        } catch {
            print("Error fetching sessions for deletion: \(error)")
            return // Keluar jika tidak bisa fetch sesi
        }

        // Hapus semua IndexOrderModels yang terkait atau semua jika tidak ada ID spesifik
        if !allSetIds.isEmpty {
            let predicateOrders = #Predicate<IndexOrderModels> { order in
                allSetIds.contains(order.sessionId)
            }
            do {
                try modelContext.delete(model: IndexOrderModels.self, where: predicateOrders)
                print("Related card orders marked for deletion.")
            } catch {
                print("Error deleting related card orders: \(error)")
            }
        } else {
            // Jika tidak ada sesi, mungkin tetap ingin menghapus semua card orders jika ada yang orphan
            // do {
            //     try modelContext.delete(model: IndexOrderModels.self)
            //     print("All card orders (potentially orphaned) marked for deletion.")
            // } catch {
            //     print("Error deleting all card orders: \(error)")
            // }
        }
        
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                print("All sessions and their card orders cleared and saved.")
            } catch {
                print("Error saving after clearing all sessions and card orders: \(error)")
            }
        } else {
            print("Clear all sessions: No changes were made that require saving.")
        }
    }
    
    // Save the order of cards for a session
    func saveCardOrder(sessionId: String, cards: [Kanji], modelContext: ModelContext) {
        // Delete any existing card order first without an immediate save
        clearCardOrder(for: sessionId, modelContext: modelContext, shouldSave: false)
        
        let indexIds = cards.map { $0.id.uuidString }
        
        let cardOrder = IndexOrderModels(sessionId: sessionId, indexIds: indexIds)
        modelContext.insert(cardOrder)
        
        updateSessionOrderFlag(sessionId: sessionId, hasOrder: true, modelContext: modelContext, shouldSave: false)
        
        if modelContext.hasChanges {
            do {
                try modelContext.save()
                print("Card order saved for session \(sessionId)")
            } catch {
                print("Error saving card order for session \(sessionId): \(error)")
            }
        }
    }
    
    // Load the saved card order for a session
    func loadCardOrder(sessionId: String, availableCards: [Kanji], modelContext: ModelContext) -> [Kanji]? {
        let predicate = #Predicate<IndexOrderModels> { order in
            order.sessionId == sessionId
        }
        let descriptor = FetchDescriptor<IndexOrderModels>(predicate: predicate)
        
        do {
            guard let cardOrder = try modelContext.fetch(descriptor).first, !cardOrder.indexIds.isEmpty else {
                return nil
            }
            
            let cardsById = Dictionary(uniqueKeysWithValues: availableCards.map { ($0.id.uuidString, $0) })
            var orderedCards: [Kanji] = []
            
            for cardIdString in cardOrder.indexIds {
                if let card = cardsById[cardIdString] {
                    orderedCards.append(card)
                } else {
                    print("Warning: Card with ID \(cardIdString) not found in available cards for session \(sessionId) during load.")
                }
            }
            
            // Validasi: jika jumlah kartu yang direkonstruksi tidak sama dengan jumlah ID yang disimpan,
            // atau tidak sama dengan jumlah kartu yang tersedia (jika ini adalah syarat), maka order mungkin tidak valid.
            // Untuk sekarang, kita akan kembalikan apa yang bisa direkonstruksi.
            // Jika ingin lebih ketat:
            if orderedCards.count != cardOrder.indexIds.count {
                 print("Card order for \(sessionId) is incomplete (expected \(cardOrder.indexIds.count) IDs, reconstructed \(orderedCards.count) cards). Invalidating this order.")
                 // Hapus order yang rusak dan update flag
                 modelContext.delete(cardOrder)
                 updateSessionOrderFlag(sessionId: sessionId, hasOrder: false, modelContext: modelContext, shouldSave: true) // simpan perubahan ini
                 return nil
            }
            // Opsional: bandingkan juga dengan availableCards.count jika seharusnya selalu sama
            // if orderedCards.count != availableCards.count {
            //     print("Card order count (\(orderedCards.count)) does not match available cards count (\(availableCards.count)) for session \(sessionId). Considering it invalid.")
            //     return nil
            // }
            
            return orderedCards
        } catch {
            print("Error loading card order for session \(sessionId): \(error)")
            return nil
        }
    }
    
    // Clear saved card order for a session
    private func clearCardOrder(for sessionId: String, modelContext: ModelContext, shouldSave: Bool = true) {
        let predicate = #Predicate<IndexOrderModels> { order in
            order.sessionId == sessionId
        }
        do {
            try modelContext.delete(model: IndexOrderModels.self, where: predicate)
            print("Card order data marked for deletion for session: \(sessionId)")
            
            updateSessionOrderFlag(sessionId: sessionId, hasOrder: false, modelContext: modelContext, shouldSave: false) // Update flag, jangan save dulu
            
            if shouldSave && modelContext.hasChanges {
                try modelContext.save()
                print("Card order cleared and saved for session: \(sessionId)")
            }
        } catch {
            print("Error clearing card order for session \(sessionId): \(error)")
        }
    }
    
    // Update the hasOrderSaved flag on a session
    private func updateSessionOrderFlag(sessionId: String, hasOrder: Bool, modelContext: ModelContext, shouldSave: Bool = true) {
        let predicate = #Predicate<FlashCardSessionModels> { session in
            session.setId == sessionId
        }
        let descriptor = FetchDescriptor<FlashCardSessionModels>(predicate: predicate)
        
        do {
            if let session = try modelContext.fetch(descriptor).first {
                if session.hasOrderSaved != hasOrder {
                    session.hasOrderSaved = hasOrder
                    print("Session order flag updated to \(hasOrder) for \(sessionId).")
                    if shouldSave && modelContext.hasChanges {
                        try modelContext.save()
                        print("Session order flag saved for \(sessionId).")
                    }
                }
            } else {
                print("Warning: Session \(sessionId) not found to update 'hasOrderSaved' flag.")
            }
        } catch {
            print("Error updating session order flag for \(sessionId): \(error)")
        }
    }
    
    // Format the last access date
    func formatLastAccessDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
