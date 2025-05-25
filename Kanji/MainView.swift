//
//  ContentView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, Hashable, FloatingTabProtocol {
    case flipcard = "Flip Card"
    case quiz = "Kuis"
    case kanji = "Kanji"
    case about = "About"
    
    var symbolImage: String {
        switch self {
        case .flipcard: "menucard"
        case .quiz: "applepencil.and.scribble"
        case .kanji: "k.square.fill"
        case .about: "person.fill"
        }
    }
}

struct MainView: View {
    @State private var activeTab: AppTab = .flipcard
    @State private var currentSafeAreaBottom: CGFloat = 0
    
    var body: some View {
        FloatingTabView(
            config: FloatingTabConfig(
                activeTint: Color(UIColor.systemBackground),
                activeBackgroundTint: .orange, // Warna baru untuk contoh
                mainButtonHPadding: 20, // Sedikit lebih jauh dari tepi kanan
                mainButtonBPadding: currentSafeAreaBottom > 0 ? currentSafeAreaBottom + 10 : 25,
                mainButtonSize: 60,// Lebih banyak padding dari bawah
                collapsedButtonIcon: "arrow.up.message.fill",
                expandedButtonIcon: "xmark.octagon.fill", // Ikon berbeda
                itemSpacingWhenExpanded: 20,
                itemSizeRatio: 0.60,
                expansionItemsBackgroundColor: Color(UIColor.tertiarySystemBackground),
                expansionItemsPadding: 10,
                dragEndAnimation: .interactiveSpring(response: 0.4, dampingFraction: 0.7) // Animasi akhir geser
            ),
            selection: $activeTab
        ) { tab, bottomSpaceToClearForButton in
            Group {
                switch tab {
                case .flipcard:
                    FlipCardContentView(bottomClearance: bottomSpaceToClearForButton)
                case .quiz:
                    QuizContentView(bottomClearance: bottomSpaceToClearForButton)
                case .kanji:
                    ListContentView(bottomClearance: bottomSpaceToClearForButton)
                case .about:
                    Text("About")
                }
            }
        }
        .onAppear {
            self.currentSafeAreaBottom = UIApplication.shared.getKeyWindow?.safeAreaInsets.bottom ?? 0
        }
    }
}

#Preview {
    MainView()
}
