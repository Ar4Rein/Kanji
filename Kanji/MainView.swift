//
//  ContentView.swift
//  Kanji
//
//  Created by Muhammad Ardiansyah on 13/05/25.
//

import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable, FloatingTabProtocol {
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
    
    var body: some View {
        FloatingTabView(selection: $activeTab) { tab, tabBarHeight in
            switch tab {
            case.flipcard: FlipCardContentView()
            case.quiz: QuizContentView()
            case.kanji: Text("Kanji")
            case.about: Text("About")
            }
        }
    }
}

#Preview {
    MainView()
}
