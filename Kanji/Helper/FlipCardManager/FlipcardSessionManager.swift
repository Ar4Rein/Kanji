//
//  FlipcardSessionManager.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 12/05/25.
//

import Foundation
import SwiftData

// Class to manage user sessions
class FlipcardSessionManager {
    static let shared = FlipcardSessionManager()
    
    private init() {}
    
    // Generate a unique ID for a kanji set
    func generateSetId(for set: KanjiSet) -> String {
        return "\(set.level)_\(set.name)"
    }
    
    // Fetch or create a session for the given kanji set
    func getOrCreateSession(for set: KanjiSet, modelContext: ModelContext) -> UserSessionCardModels {
        let setId = generateSetId(for: set)
        
        // Try to find existing session
        let predicate = #Predicate<UserSessionCardModels> { session in
            session.setId == setId
        }
        let descriptor = FetchDescriptor<UserSessionCardModels>(predicate: predicate)
        
        do {
            let existingSessions = try modelContext.fetch(descriptor)
            if let existingSession = existingSessions.first {
                // Update last access date
                existingSession.lastAccessDate = Date()
                return existingSession
            }
        } catch {
            print("Error fetching session: \(error)")
        }
        
        // Create new session if none exists
        let newSession = UserSessionCardModels(setId: setId)
        modelContext.insert(newSession)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving new session: \(error)")
        }
        
        return newSession
    }
    
    // Update session data
    func updateSession(session: UserSessionCardModels, currentIndex: Int, totalCards: Int, modelContext: ModelContext) {
        session.lastViewedCardIndex = currentIndex
        session.completionPercentage = min(Double(currentIndex + 1) / Double(totalCards), 1.0)
        session.lastAccessDate = Date()
        
        do {
            try modelContext.save()
            print("Session updated: \(session.setId), Card: \(currentIndex), Completion: \(session.completionPercentage * 100)%")
        } catch {
            print("Error updating session: \(error)")
        }
    }
    
    // Clear session data for a set (e.g., when user completes the set)
    func clearSession(for set: KanjiSet, modelContext: ModelContext) {
        let setId = generateSetId(for: set)
        
        // Clear session
        clearSessionWithId(setId: setId, modelContext: modelContext)
        
        // Also clear the card order
        clearCardOrder(for: setId, modelContext: modelContext)
    }
    
    // Clear a session by its ID
    private func clearSessionWithId(setId: String, modelContext: ModelContext) {
        let predicate = #Predicate<UserSessionCardModels> { session in
            session.setId == setId
        }
        let descriptor = FetchDescriptor<UserSessionCardModels>(predicate: predicate)
        
        do {
            let existingSessions = try modelContext.fetch(descriptor)
            if let existingSession = existingSessions.first {
                modelContext.delete(existingSession)
                try modelContext.save()
                print("Session cleared for \(setId)")
            }
        } catch {
            print("Error clearing session: \(error)")
        }
    }
    
    // Clear all sessions
    func clearAllSessions(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserSessionCardModels>()
        
        do {
            let allSessions = try modelContext.fetch(descriptor)
            for session in allSessions {
                modelContext.delete(session)
                
                // Also clear card order for this session
                clearCardOrder(for: session.setId, modelContext: modelContext)
            }
            
            try modelContext.save()
            print("All sessions cleared")
        } catch {
            print("Error clearing all sessions: \(error)")
        }
    }
    
    // Save the order of cards for a session
    func saveCardOrder(sessionId: String, cards: [Kanji], modelContext: ModelContext) {
        // Delete any existing card order
        clearCardOrder(for: sessionId, modelContext: modelContext)
        
        // Create card IDs list
        let indexIds = cards.map { $0.id.uuidString }
        
        // Create and save new card order
        let cardOrder = IndexOrderModels(sessionId: sessionId, indexIds: indexIds)
        modelContext.insert(cardOrder)
        
        // Mark session as having saved order
        updateSessionOrderFlag(sessionId: sessionId, hasOrder: true, modelContext: modelContext)
        
        do {
            try modelContext.save()
            print("Card order saved for session \(sessionId)")
        } catch {
            print("Error saving card order: \(error)")
        }
    }
    
    // Load the saved card order for a session
    func loadCardOrder(sessionId: String, availableCards: [Kanji], modelContext: ModelContext) -> [Kanji]? {
        let predicate = #Predicate<IndexOrderModels> { order in
            order.sessionId == sessionId
        }
        let descriptor = FetchDescriptor<IndexOrderModels>(predicate: predicate)
        
        do {
            let orders = try modelContext.fetch(descriptor)
            guard let cardOrder = orders.first, !cardOrder.indexIds.isEmpty else {
                return nil
            }
            
            // Create a dictionary of available cards by ID for quick lookup
            let cardsById = Dictionary(uniqueKeysWithValues: availableCards.map { (($0.id.uuidString), $0) })
            
            // Reconstruct the card order
            var orderedCards: [Kanji] = []
            
            for cardId in cardOrder.indexIds {
                if let card = cardsById[cardId] {
                    orderedCards.append(card)
                }
            }
            
            // If we couldn't reconstruct the full order (some cards missing), return nil
            if orderedCards.count != availableCards.count {
                print("Card order incomplete, falling back to default")
                return nil
            }
            
            return orderedCards
        } catch {
            print("Error loading card order: \(error)")
            return nil
        }
    }
    
    // Clear saved card order for a session
    private func clearCardOrder(for sessionId: String, modelContext: ModelContext) {
        let predicate = #Predicate<IndexOrderModels> { order in
            order.sessionId == sessionId
        }
        let descriptor = FetchDescriptor<IndexOrderModels>(predicate: predicate)
        
        do {
            let orders = try modelContext.fetch(descriptor)
            for order in orders {
                modelContext.delete(order)
            }
            
            // Mark session as not having saved order
            updateSessionOrderFlag(sessionId: sessionId, hasOrder: false, modelContext: modelContext)
            
            try modelContext.save()
        } catch {
            print("Error clearing card order: \(error)")
        }
    }
    
    // Update the hasOrderSaved flag on a session
    private func updateSessionOrderFlag(sessionId: String, hasOrder: Bool, modelContext: ModelContext) {
        let predicate = #Predicate<UserSessionCardModels> { session in
            session.setId == sessionId
        }
        let descriptor = FetchDescriptor<UserSessionCardModels>(predicate: predicate)
        
        do {
            let sessions = try modelContext.fetch(descriptor)
            if let session = sessions.first {
                session.hasOrderSaved = hasOrder
            }
        } catch {
            print("Error updating session order flag: \(error)")
        }
    }
    
    // Format the last access date as a readable string
    func formatLastAccessDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
