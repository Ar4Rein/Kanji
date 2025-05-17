//
//  KanjiQuizView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

struct KanjiQuizView: View {
    // Environment
    @Environment(\.modelContext) private var modelContext
    
    // Properties
    let kanjiSet: KanjiSet
    
    // State variables
    @State private var currentCardIndex = 0
    @State private var quizCards: [Kanji] = []
    @State private var userInput = ""
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var showCompletionAlert = false
    @State private var session: UserSessionCardModels?
    @State private var hideTabBar: Bool = false
    
    // Focus state for text field
    @FocusState private var isInputFocused: Bool
    
    // Computed properties
    private var currentCard: Kanji? {
        guard !quizCards.isEmpty, currentCardIndex < quizCards.count else { return nil }
        return quizCards[currentCardIndex]
    }
    
    private var progress: Double {
        guard !quizCards.isEmpty else { return 0 }
        return Double(currentCardIndex + 1) / Double(quizCards.count)
    }
    
    var body: some View {
        VStack {
            // Card counter with session info
            Text("\(currentCardIndex + 1) / \(quizCards.count)")
                .font(.headline)
            
            // Progress indicator
            ProgressView(value: progress)
                .padding(.horizontal, 40)
            
            // Card display area
            if let card = currentCard {
                VStack(spacing: 20) {
                    // Kanji display
                    Text(card.kanji)
                        .font(.system(size: 80, weight: .medium))
                        .padding(.bottom, 20)
                    
                    // Input field
                    SpecificLanguageTextFieldView(placeHolder: "Tulis dalam hiragana", language: "ja-JP", text: $userInput)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                        .focused($isInputFocused)
                        .onSubmit {
                            checkAnswer()
                        }
                        .disabled(showFeedback)
                        .frame(height: 50)
                    
                    // Submit button
                    Button(action: checkAnswer) {
                        Text("Check")
                            .font(.title3.bold())
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    .disabled(userInput.isEmpty || showFeedback)
                }
                .hideFloatingTabBar(hideTabBar)
            } else {
                Text("No cards loaded")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .navigationTitle("\(kanjiSet.level) - \(kanjiSet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {
                        withAnimation(.bouncy) {
                            hideKeyboard()
                        }
                    }) {
                        Label("Hide Keyboard", systemImage: "keyboard.chevron.compact.down")
                    }
                    Button(action: {
                        withAnimation(.bouncy) {
                            hideTabBar.toggle()
                        }
                    }) {
                        Label("Hide Tab Bar", systemImage: "eye.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            loadQuizData()
        }
        .sheet(isPresented: $showFeedback) {
            feedbackView
                .padding(.horizontal, 40)
                .presentationDetents([.fraction(0.8)])
        }
        .alert("Quiz Completed", isPresented: $showCompletionAlert) {
            Button("Restart Quiz") {
                resetQuiz()
            }
            Button("Return to List", role: .cancel) { }
        } message: {
            Text("You've completed all the kanji cards in this set!")
        }
    }
    
    private func hideKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // Feedback view shown after answering
    private var feedbackView: some View {
        VStack(spacing: 30) {
            // Feedback header
            if isCorrect {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Correct!")
                    .font(.title.bold())
                    .foregroundColor(.green)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)
                
                Text("Not quite right")
                    .font(.title.bold())
                    .foregroundColor(.red)
            }
            
            // Content display
            VStack(alignment: .leading, spacing: 20) {
                KanjiDetailRow(label: "Kanji", content: currentCard?.kanji ?? "")
                KanjiDetailRow(label: "Reading", content: currentCard?.reading ?? "")
                KanjiDetailRow(label: "Meaning", content: currentCard?.meaning ?? "")
                
                if !isCorrect {
                    Text("You entered: \(userInput)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Continue button
            Button(action: {
                showFeedback = false
                if currentCardIndex < quizCards.count - 1 {
                    nextCard()
                } else {
                    showCompletionAlert = true
                }
            }) {
                Text("Continue")
                    .font(.title3.bold())
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(20)
        .presentationDetents([.medium])
    }
    
    // MARK: - Helper Functions
    
    // Load quiz data
    private func loadQuizData() {
        // Try to get/create a session
        session = FlipcardSessionManager.shared.getOrCreateSession(for: kanjiSet, modelContext: modelContext)
        
        // Load cards from set
        quizCards = kanjiSet.items
        
        // Shuffle cards if needed or load saved order
        if let session = session, session.hasOrderSaved {
            if let savedOrder = FlipcardSessionManager.shared.loadCardOrder(sessionId: session.setId, availableCards: kanjiSet.items, modelContext: modelContext) {
                quizCards = savedOrder
            } else {
                // If saved order loading fails, create new shuffled order
                quizCards.shuffle()
                FlipcardSessionManager.shared.saveCardOrder(sessionId: session.setId, cards: quizCards, modelContext: modelContext)
            }
        } else {
            // No saved order, create new shuffled order
            quizCards.shuffle()
            if let session = session {
                FlipcardSessionManager.shared.saveCardOrder(sessionId: session.setId, cards: quizCards, modelContext: modelContext)
            }
        }
        
        // Restore session progress if available
        if let session = session, session.lastViewedCardIndex < quizCards.count {
            currentCardIndex = session.lastViewedCardIndex
        }
        
        // Update session
        updateSession()
    }
    
    // Check user's answer
    private func checkAnswer() {
        guard let card = currentCard, !userInput.isEmpty else { return }
        
        isCorrect = userInput.trimmingCharacters(in: .whitespacesAndNewlines) == card.reading.trimmingCharacters(in: .whitespacesAndNewlines)
        showFeedback = true
        
        // Clear focus
        isInputFocused = false
    }
    
    // Navigate to next card
    private func nextCard() {
        if currentCardIndex < quizCards.count - 1 {
            currentCardIndex += 1
            userInput = ""
            updateSession()
        }
    }
    
    // Navigate to previous card
    private func previousCard() {
        if currentCardIndex > 0 {
            currentCardIndex -= 1
            userInput = ""
            updateSession()
        }
    }
    
    // Reset quiz
    private func resetQuiz() {
        currentCardIndex = 0
        userInput = ""
        showFeedback = false
        
        // Shuffle cards
        quizCards.shuffle()
        
        // Save new order
        if let session = session {
            FlipcardSessionManager.shared.saveCardOrder(sessionId: session.setId, cards: quizCards, modelContext: modelContext)
        }
        
        updateSession()
    }
    
    // Update session data
    private func updateSession() {
        if let session = session {
            FlipcardSessionManager.shared.updateSession(
                session: session,
                currentIndex: currentCardIndex,
                totalCards: quizCards.count,
                modelContext: modelContext
            )
        }
    }
}

// Helper view for displaying details
struct KanjiDetailRow: View {
    let label: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(content)
                .font(.title2)
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KanjiSet.self, Kanji.self, configurations: config)
    
    // Create a sample KanjiSet with cards for preview
    let exampleSet = KanjiSet(level: "N5", name: "Example Set")
    let cards = [
        Kanji(id: UUID(), kanji: "木", reading: "き", meaning: "tree"),
        Kanji(id: UUID(), kanji: "水", reading: "みず", meaning: "water"),
        Kanji(id: UUID(), kanji: "火", reading: "ひ", meaning: "fire")
    ]
    exampleSet.items = cards
    
    return NavigationStack {
        KanjiQuizView(kanjiSet: exampleSet)
    }
    .modelContainer(container)
}
