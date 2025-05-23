//
//  QuizGenerator.swift
//  Quiz
//
//  Created by Muhammad Ardiansyah on 19/05/25.
//

// Utils/QuizGenerator.swift
import Foundation

class QuizGenerator {

    // MARK: - Pembuatan Pertanyaan Pilihan Ganda
    // ... (kode Pilihan Ganda tidak berubah, biarkan seperti adanya) ...
    func generateMultipleChoiceQuestion(from kanji: Kanji, allKanjisInSet: [Kanji], forcedType: QuizQuestionTypeMC? = nil) -> QuizQuestion? {
        // Tentukan tipe pertanyaan yang mungkin dibuat berdasarkan data yang tersedia pada Kanji.
        var possibleTypes = QuizQuestionTypeMC.allCases
        if kanji.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            possibleTypes.removeAll { $0 == .kanjiToReading } // Hapus jika tidak ada data bacaan.
        }
        if kanji.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            possibleTypes.removeAll { $0 == .kanjiToMeaning || $0 == .meaningToKanji } // Hapus jika tidak ada data arti.
        }

        guard !possibleTypes.isEmpty else {
            return nil
        }

        let type = forcedType ?? possibleTypes.randomElement()!
        
        var questionText: String
        var correctAnswer: String
        var incorrectOptionSourceAttribute: (Kanji) -> String
        var attributeToCheckForIncorrectNotEmpty: (Kanji) -> String

        switch type {
        case .kanjiToMeaning:
            questionText = "Apa arti dari kanji \"\(kanji.kanji)\"?"
            correctAnswer = kanji.meaning
            incorrectOptionSourceAttribute = { $0.meaning }
            attributeToCheckForIncorrectNotEmpty = { $0.meaning }
        case .meaningToKanji:
            questionText = "Kanji mana yang memiliki arti \"\(kanji.meaning)\"?"
            correctAnswer = kanji.kanji
            incorrectOptionSourceAttribute = { $0.kanji }
            attributeToCheckForIncorrectNotEmpty = { $0.kanji }
        case .kanjiToReading:
            questionText = "Bagaimana cara membaca kanji \"\(kanji.kanji)\"?"
            correctAnswer = kanji.reading
            incorrectOptionSourceAttribute = { $0.reading }
            attributeToCheckForIncorrectNotEmpty = { $0.reading }
        }

        let numberOfOptions = 4
        var options: [String] = [correctAnswer]

        let potentialIncorrectSources = allKanjisInSet.filter {
            let attributeValue = incorrectOptionSourceAttribute($0)
            let checkAttributeValue = attributeToCheckForIncorrectNotEmpty($0)
            return $0.id != kanji.id &&
                   attributeValue != correctAnswer &&
                   !checkAttributeValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.shuffled()

        for incorrectKanji in potentialIncorrectSources {
            if options.count < numberOfOptions {
                let incorrectOption = incorrectOptionSourceAttribute(incorrectKanji)
                if !options.contains(incorrectOption) {
                    options.append(incorrectOption)
                }
            } else {
                break
            }
        }

        if options.count < 2 {
            return nil
        }
        
        options.shuffle()
        
        guard let correctIdx = options.firstIndex(of: correctAnswer) else {
            return nil
        }

        return QuizQuestion(kanjiSource: kanji, questionText: questionText, options: options, correctAnswerIndex: correctIdx, questionType: type)
    }

    func generateAllMultipleChoiceQuestions(fromKanjis kanjisToAsk: [Kanji], allKanjisInSet: [Kanji]) -> [QuizQuestion] {
        return kanjisToAsk.compactMap { generateMultipleChoiceQuestion(from: $0, allKanjisInSet: allKanjisInSet) }
    }

    // MARK: - Pembuatan Pertanyaan Input Teks
    // DIMODIFIKASI: Fungsi ini sekarang lebih baik dalam menangani `forcedType`.
    func generateTextInputQuestion(from kanji: Kanji, forcedType: QuizQuestionTypeTI? = nil) -> QuizTextInputQuestion? {
        var chosenType: QuizQuestionTypeTI

        if let type = forcedType {
            chosenType = type
            // Jika tipe dipaksa, periksa apakah data yang diperlukan ada.
            switch chosenType {
            case .kanjiToReadingInput:
                if kanji.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // print("Input Teks: Dipaksa ke .kanjiToReadingInput, tapi Kanji \(kanji.kanji) tidak punya bacaan.")
                    return nil // Tidak bisa membuat tipe soal ini.
                }
            case .kanjiToMeaningInput:
                if kanji.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    // print("Input Teks: Dipaksa ke .kanjiToMeaningInput, tapi Kanji \(kanji.kanji) tidak punya arti.")
                    return nil // Tidak bisa membuat tipe soal ini.
                }
            }
        } else {
            // Tentukan tipe yang mungkin jika tidak dipaksa.
            var possibleTypes = QuizQuestionTypeTI.allCases
            if kanji.reading.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                possibleTypes.removeAll { $0 == .kanjiToReadingInput }
            }
            if kanji.meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                possibleTypes.removeAll { $0 == .kanjiToMeaningInput }
            }

            guard let randomType = possibleTypes.randomElement() else {
                // print("Input Teks: Tidak ada tipe pertanyaan yang valid (non-forced) untuk Kanji \(kanji.kanji)")
                return nil
            }
            chosenType = randomType
        }

        var questionText: String
        var correctAnswerString: String

        switch chosenType {
        case .kanjiToReadingInput:
            questionText = "Ketik bacaan (Hiragana/Katakana) untuk kanji:\n\n\"\(kanji.kanji)\""
            correctAnswerString = kanji.reading
        case .kanjiToMeaningInput:
            questionText = "Ketik arti utama dalam bahasa Indonesia untuk kanji:\n\n\"\(kanji.kanji)\""
            correctAnswerString = kanji.meaning
        }

        return QuizTextInputQuestion(kanjiSource: kanji, questionText: questionText, correctAnswerString: correctAnswerString, questionType: chosenType)
    }

    // DIMODIFIKASI: Tambahkan parameter `hiraganaOnly`
    func generateAllTextInputQuestions(fromKanjis kanjisToAsk: [Kanji], hiraganaOnly: Bool = false) -> [QuizTextInputQuestion] {
        return kanjisToAsk.compactMap { kanji in
            if hiraganaOnly {
                // Coba buat soal input hiragana.
                // generateTextInputQuestion akan return nil jika kanji.reading kosong.
                return generateTextInputQuestion(from: kanji, forcedType: .kanjiToReadingInput)
            } else {
                // Biarkan generateTextInputQuestion memilih secara acak berdasarkan data yang ada.
                return generateTextInputQuestion(from: kanji, forcedType: nil)
            }
        }
    }
}
