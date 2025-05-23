//
//  QuizContent.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

struct QuizContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var tabViewHelper: FLoatingTabViewHelper
    
    @Query var sessions: [QuizSessionModels]
    @State private var tab: AppTab = .quiz
    @State private var isLoading = false
    @State private var showConfirmClearAll = false
    
    var bottomClearance: CGFloat
    
    var body: some View {
        NavigationStack {
            if isLoading {
                loadingView
            } else {
                KanjiSetQuizView()
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
                                    
                                    print("hide the tabbar")
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
                            
                        }
                    } message: {
                        Text("This will reset progress for all kanji sets. This action cannot be undone.")
                    }
            }
        }
        .onAppear {
            
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading Kanji Data...")
                .font(.headline)
        }
    }
}

//#Preview {
//    QuizContentView()
//        .modelContainer(for: [KanjiSet.self, Kanji.self, UserSessionCardModels.self, IndexOrderModels.self], inMemory: true)
//}
