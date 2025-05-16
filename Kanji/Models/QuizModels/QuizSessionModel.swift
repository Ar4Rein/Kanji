//
//  QuizSessionModel.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 16/05/25.
//

import Foundation
import SwiftData

@Model
class QuizSessionModel {
    var setId: String
    var currentQuestionIndex: Int
    var correctAnswers: Int
    var totalQuestions: Int
    var lastAccessDate: Date
    
    init(setId: String, currentQuestionIndex: Int = 0, correctAnswers: Int = 0, totalQuestions: Int = 0) {
        self.setId = setId
        self.currentQuestionIndex = currentQuestionIndex
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.lastAccessDate = Date()
    }
}
