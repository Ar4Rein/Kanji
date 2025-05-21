	//
//  KanjiCardView.swift
//  KanjiFlashcard
//
//  Created by Muhammad Ardiansyah on 11/05/25.
//

import SwiftUI

struct FlashCardComponentView: View {
    var card: Kanji
    @State private var isFlipped = false
    @State private var degree = 0.0
    
    @State private var fontWeight: Font.Weight = .regular
    
    var body: some View {
        ZStack {
            // Front side (Kanji)
            CardFace(content: {
                VStack(spacing: 20) {
                    Text(card.kanji)
                        .font(.system(size: 80))
                        .fontWeight(fontWeight)
                    
                    Text("Tap to flip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            })
            .opacity(isFlipped ? 0 : 1)
            .rotation3DEffect(
                .degrees(degree),
                axis: (x: 0, y: 1, z: 0)
            )
            
            // Back side (Reading & Meaning)
            CardFace(content: {
                VStack(spacing: 10) {
                    Text(card.reading)
                        .font(.system(size: 60))
                        .fontWeight(fontWeight)
                    
                    Text(card.meaning)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Tap to flip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
            })
            .opacity(isFlipped ? 1 : 0)
            .rotation3DEffect(
                .degrees(degree - 180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
        .frame(width: 330, height: 450)
        .onTapGesture {
            flipCard()
        }
    }
    
    private func flipCard() {
        withAnimation(.spring(duration: 0.1)) {
            isFlipped.toggle()
            degree += 180
        }
    }
}

struct CardFace<Content: View>: View {
    var content: () -> Content
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            
            content()
        }
    }
}

#Preview {
    FlashCardComponentView(card: Kanji(id: UUID(),kanji: "秋", reading: "あき", meaning: "Musim gugur"))
        .padding()
        .preferredColorScheme(.dark)
}
