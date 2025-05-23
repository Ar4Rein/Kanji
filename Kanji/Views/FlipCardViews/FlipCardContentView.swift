//
//  ContentView.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import SwiftUI
import SwiftData

struct FlipCardContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var sessions: [FlashCardSessionModels]
    @State private var tab: AppTab = .quiz
    @State private var isLoading = false
    @State private var showConfirmClearAll = false
    @State private var hideTabBar: Bool = false
    
    var body: some View {
        NavigationStack {
            if isLoading {
                loadingView
            } else {
                KanjiSetFlipCardView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Menu {
                                Button(role: .destructive, action: {
                                    showConfirmClearAll = true
                                }) {
                                    Label("Clear All Progress", systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "gear")
                            }
                        }
                        
                        ToolbarItem(placement: .topBarLeading) {
                            Menu {
                                Button(role: .destructive, action: {
                                    hideTabBar.toggle()
                                }) {
                                    Label("Hide Tab Bar", systemImage: "eye.slash")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                            }
                        }
                    }
                    .alert("Clear All Progress?", isPresented: $showConfirmClearAll) {
                        Button("Cancel", role: .cancel) {}
                        Button("Clear", role: .destructive) {
                            clearAllSessions()
                        }
                    } message: {
                        Text("This will reset progress for all kanji sets. This action cannot be undone.")
                    }
            }
        }
        .hideFloatingTabBar(hideTabBar)
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Kanji Data...")
                .font(.headline)
        }
    }

    private func clearAllSessions() {
        FlipcardSessionManager.shared.clearAllSessions(modelContext: modelContext)
    }
}

#Preview {
    FlipCardContentView()
        .modelContainer(for: [KanjiSet.self, FlashCardSessionModels.self, IndexOrderModels.self], inMemory: true)
}
