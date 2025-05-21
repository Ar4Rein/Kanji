//
//  FlashcardDeckView.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import SwiftUI

struct FlashCardView: View {
    var kanjiSet: KanjiSet
    @State private var currentIndex = 0
    @State private var offset = CGSize.zero
    @State private var cardBackground = Color.white
    @State private var showingProgress = false
    @State private var shuffledCards: [Kanji] = []
    @State private var currentSession: FlashCardSessionModels?
    @State private var isFirstLoad = true
    @State private var animation: Animation = .bouncy
    @State private var hideTabBar: Bool = false
    
    @State private var swipeDirection: SwipeDirection = .none

    enum SwipeDirection {
        case left, right, none
    }
    
    @Environment(\.modelContext) private var modelContext
    
    func progressWidth(currentIndex: Int, total: Int) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(currentIndex + 1) / CGFloat(total) * UIScreen.main.bounds.width * 0.8
    }
    
    var body: some View {
        VStack {
            // Card counter with session info
            HStack {
                Text("\(currentIndex + 1) / \(shuffledCards.count)")
                    .font(.headline)
                
                if let session = currentSession, session.hasOrderSaved {
                    Text("• Resuming session")
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
                    .foregroundStyle(.blue)
            }
            .frame(width: UIScreen.main.bounds.width * 0.8)
            .padding(.bottom)
            
            // Card deck
            ZStack {
                ForEach(Array(shuffledCards.enumerated()), id: \.element.id) { index, card in
                    if index >= currentIndex && index <= currentIndex + 1 {
                        FlashCardComponentView(card: card)
                            .scaleEffect(index == currentIndex ? 1.0 : 0.9)
                            .offset(
                                x: index == currentIndex ? offset.width :
                                   (index < currentIndex ? -50 : 50),
                                y: index == currentIndex ? offset.height : 0
                            )

                            .opacity(
                                index == currentIndex ? 1.0 :
                                (index == currentIndex + 1 || index == currentIndex - 1 ? 0.0 : 0.0)
                            )
                            .zIndex(Double(shuffledCards.count - index))
                            .transition(.move(edge: .leading))
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        if index == currentIndex {
                                            offset = gesture.translation
                                        }
                                    }
                                    .onEnded { _ in
                                        withAnimation(animation) {
                                            if offset.width < -100 && currentIndex < shuffledCards.count - 1 {
                                                swipeDirection = .left
                                                currentIndex += 1
                                                updateSession()
                                            } else if offset.width > 100 && currentIndex > 0 {
                                                swipeDirection = .right
                                                currentIndex -= 1
                                                updateSession()
                                            } else {
                                                if currentIndex == shuffledCards.count - 1 {
                                                    showingProgress = true
                                                }
                                                swipeDirection = .none
                                            }
                                            offset = .zero
                                        }
                                    }
                            )
                    }
                }
            }
            .padding(.vertical)
            
            // Navigation buttons
//            HStack(spacing: 40) {
//                Button(action: {
//                    withAnimation(animation) {
//                        if currentIndex > 0 {
//                            swipeDirection = .left
//                            currentIndex -= 1
//                            updateSession()
//                        }
//                    }
//                }) {
//                    Image(systemName: "arrow.left.circle.fill")
//                        .resizable()
//                        .frame(width: 50, height: 50)
//                }
//                .disabled(currentIndex == 0)
//                .opacity(currentIndex == 0 ? 0.3 : 1.0)
//                
//                Button(action: {
//                    withAnimation(animation) {
//                        shuffleCards()
//                        updateSession()
//                    }
//                }) {
//                    Image(systemName: "shuffle.circle.fill")
//                        .resizable()
//                        .frame(width: 50, height: 50)
//                        .foregroundStyle(.purple)
//                }
//                
//                Button(action: {
//                    withAnimation(animation) {
//                        if currentIndex < shuffledCards.count - 1 {
//                            swipeDirection = .right
//                            currentIndex += 1
//                            updateSession()
//                        } else {
//                            // Show progress if reached the end
//                            showingProgress = true
//                        }
//                    }
//                }) {
//                    Image(systemName: "arrow.right.circle.fill")
//                        .resizable()
//                        .frame(width: 50, height: 50)
//                }
//                .disabled(currentIndex == shuffledCards.count)
//                .opacity(currentIndex == shuffledCards.count ? 0.3 : 1.0)
//            }
//            .foregroundStyle(.blue)
//            .padding()
        }
        .navigationTitle(kanjiSet.name)
        .navigationBarTitleDisplayMode(.inline)
        .hideFloatingTabBar(hideTabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        hideTabBar.toggle()
                    }) {
                        Label("Hide Tab Bar", systemImage: "eye.slash")
                    }
                    Button(action: {
                        withAnimation(animation) {
                            currentIndex = 0
                            updateSession()
                        }
                    }) {
                        Label("Reset to First Card", systemImage: "arrow.counterclockwise")
                    }
                    
                    Button(action: {
                        withAnimation(animation) {
                            shuffleCards()
                            currentIndex = 0
                            updateSession()
                            
                            // Save the new card order
                            if let session = currentSession {
                                FlipcardSessionManager.shared.saveCardOrder(
                                    sessionId: session.setId,
                                    cards: shuffledCards,
                                    modelContext: modelContext
                                )
                            }
                        }
                    }) {
                        Label("Shuffle Cards", systemImage: "shuffle")
                    }
                    
                    Button(role: .destructive, action: {
                        withAnimation(animation) {
                            clearSession()
                            shuffleCards()
                            currentIndex = 0
                        }
                    }) {
                        Label("Clear Progress", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Set Completed!", isPresented: $showingProgress) {
            Button("Continue") {
                showingProgress = false
            }
            
            Button("Reset Set", role: .destructive) {
                clearSession()
                shuffleCards()
                currentIndex = 0
            }
        } message: {
            Text("You've reviewed all \(shuffledCards.count) cards in this set.")
        }
        .onAppear {
            loadSession()
            hideTabBar.toggle()
        }
        // Update session when leaving the view
        .onDisappear {
            updateSession()
            hideTabBar.toggle()
            
            // Save card order when leaving if we have cards
            if let session = currentSession, !shuffledCards.isEmpty {
                FlipcardSessionManager.shared.saveCardOrder(
                    sessionId: session.setId,
                    cards: shuffledCards,
                    modelContext: modelContext
                )
            }
        }
    }
    
    // Load or create a session for this kanji set
    private func loadSession() {
        // Get or create the session
        currentSession = FlipcardSessionManager.shared.getOrCreateSession(for: kanjiSet, modelContext: modelContext)
        
        if let session = currentSession {
            if session.hasOrderSaved && session.lastViewedCardIndex >= 0 {
                // Try to load saved card order
                if let savedCards = FlipcardSessionManager.shared.loadCardOrder(
                    sessionId: session.setId,
                    availableCards: kanjiSet.items,
                    modelContext: modelContext
                ) {
                    // Use the saved order
                    shuffledCards = savedCards
                    
                    // Set the current index from the session
                    currentIndex = min(session.lastViewedCardIndex, shuffledCards.count - 1)
                    print("Restored session with \(shuffledCards.count) cards at index \(currentIndex)")
                } else {
                    // Fallback to regular shuffle if saved order can't be loaded
                    shuffleCards()
                    currentIndex = 0
                }
            } else {
                // No saved order, just shuffle
                shuffleCards()
                
                if session.lastViewedCardIndex > 0 {
                    // If we had a previous index but no saved order, at least restore the index
                    currentIndex = min(session.lastViewedCardIndex, shuffledCards.count - 1)
                }
            }
        } else {
            // Default behavior
            shuffleCards()
        }
        
        isFirstLoad = false
    }
    
    // Update the current session
    private func updateSession() {
        if let session = currentSession {
            FlipcardSessionManager.shared.updateSession(
                session: session,
                currentIndex: currentIndex,
                totalCards: shuffledCards.count,
                modelContext: modelContext
            )
        }
    }
    
    // Clear the session and card order data
    private func clearSession() {
        FlipcardSessionManager.shared.clearSession(for: kanjiSet, modelContext: modelContext)
        // Get a fresh session
        currentSession = FlipcardSessionManager.shared.getOrCreateSession(for: kanjiSet, modelContext: modelContext)
    }
    
    // Shuffle cards and reset index
    func shuffleCards() {
        shuffledCards = kanjiSet.items.shuffled()
        currentIndex = 0
    }
}

#Preview {
    NavigationStack {
        FlashCardView(kanjiSet: KanjiSet(
            level: "N5",
            name: "kata_kerja_n5",
            items: [
                Kanji(id: UUID(), kanji: "秋", reading: "あき", meaning: "Musim gugur"),
                Kanji(id: UUID(), kanji: "冬", reading: "ふゆ", meaning: "Musim dingin"),
                Kanji(id: UUID(), kanji: "春", reading: "はる", meaning: "Musim semi"),
                Kanji(id: UUID(), kanji: "夏", reading: "なつ", meaning: "Musim panas"),
                Kanji(id: UUID(), kanji: "日", reading: "ひ", meaning: "Hari/Matahari"),
            ]
        ))
    }
    .modelContainer(for: [KanjiSet.self, FlashCardSessionModels.self, IndexOrderModels.self], inMemory: true)
}
