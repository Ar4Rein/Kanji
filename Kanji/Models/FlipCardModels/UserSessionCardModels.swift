//
//  UserSessionModels.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 12/05/25.
//

import Foundation
import SwiftData

// Model to track user's session information for each kanji set
@Model
class UserSessionCardModels {
    var setId: String          // Unique identifier for the set (level + name)
    var lastViewedCardIndex: Int
    var completionPercentage: Double
    var lastAccessDate: Date
    var hasOrderSaved: Bool    // Flag to indicate if card order is saved
    
    init(setId: String, lastViewedCardIndex: Int = 0, completionPercentage: Double = 0.0, hasOrderSaved: Bool = false) {
        self.setId = setId
        self.lastViewedCardIndex = lastViewedCardIndex
        self.completionPercentage = completionPercentage
        self.lastAccessDate = Date()
        self.hasOrderSaved = hasOrderSaved
    }
}
