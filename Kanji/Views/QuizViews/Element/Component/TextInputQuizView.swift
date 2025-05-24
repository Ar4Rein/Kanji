//
//  TextInputQuizView.swift
//  Quiz
//
//  Created by Muhammad Ardiansyah on 19/05/25.
//

// Views/TextInputQuizView.swift
import SwiftUI

struct TextInputQuizView: View {
    let kanjiSet: KanjiSet
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var quizSession: QuizSessionModels?
    @State private var currentQuestion: QuizTextInputQuestion?
    @State private var allQuestions: [QuizTextInputQuestion] = []

    @State private var userAnswer: String = ""
    @State private var showFeedback = false
    @State private var feedbackMessage = ""
    @State private var isAnswerCorrect: Bool? = nil
    @State private var isLoading = true
    @State private var isQuizFinished = false
    @FocusState private var isTextFieldFocused: Bool

    @State private var hideTabBar: Bool = false
    @State private var hiraganaOnlyMode: Bool = false // <-- STATE BARU untuk toggle

    var body: some View {
        VStack(spacing: 15) {
            if isLoading {
                ProgressView("Memuat Kuis Input Teks...")
            } else if isQuizFinished, let session = quizSession {
                QuizCompletionView(session: session, onRestart: restartQuiz, onDismiss: { dismiss() })
            } else if let question = currentQuestion, let session = quizSession {
                QuizHeaderView(session: session)

                Text(question.questionText)
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .padding()
                    .minimumScaleFactor(0.7)

                if !hiraganaOnlyMode {
                    TextField("Ketik jawabanmu di sini", text: $userAnswer)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !showFeedback {
                                checkAnswer()
                            }
                        }
                        .disabled(showFeedback)
                } else {
                    SpecificLanguageTextFieldView(placeHolder: "Tulis dalam hiragana", language: "ja-JP", text: $userAnswer)
                        .textFieldStyle(.roundedBorder)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .submitLabel(.done)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            if !userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !showFeedback {
                                checkAnswer()
                            }
                        }
                        .disabled(showFeedback)
                }
                

                Spacer()

                if showFeedback {
                    VStack {
                        Text(feedbackMessage)
                            .font(.title)
                            .foregroundColor(isAnswerCorrect == true ? .green : .red)
                    }
                    .padding(.vertical)
                    
                    Button(session.currentQuestionIndex + 1 >= session.totalQuestions ? "Lihat Hasil" : "Lanjut") {
                        proceedToNextQuestionOrFinish()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom)
                } else {
                    Button("Periksa Jawaban") {
                        checkAnswer()
                        isTextFieldFocused = false
                    }
                    .buttonStyle(.bordered)
                    .disabled(userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.bottom)
                }
            } else {
                Text(allQuestions.isEmpty && !isLoading ? "Tidak ada pertanyaan yang dapat ditampilkan dengan mode filter saat ini." : "Tidak ada pertanyaan tersedia atau kuis telah selesai.")
                Button("Kembali") { dismiss() }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        hideTabBar.toggle()
                        // print("hide the tabbar") // Komentar bisa dihapus jika tidak perlu
                    }) {
                        Label("Hide Tab Bar", systemImage: "eye.slash")
                    }

                    // <-- TOGGLE BARU DITAMBAHKAN DI SINI -->
                    Toggle(isOn: $hiraganaOnlyMode) {
                        Text("Mode Hiragana Saja")
                    }
                    
                } label: {
                    Image(systemName: "ellipsis.circle") // Menggunakan ikon yang lebih umum untuk menu
                }
            }
        }
        .onChange(of: hiraganaOnlyMode) { // <-- DETEKSI PERUBAHAN TOGGLE
            print("Mode Hiragana Saja diubah menjadi: \(hiraganaOnlyMode). Memulai ulang kuis.")
            restartQuiz() // Panggil restartQuiz untuk memuat ulang soal dengan mode baru
        }
        .onAppear {
            // hideTabBar.toggle() // Perilaku asli, mungkin perlu disesuaikan jika tidak ingin toggle otomatis
            if !hideTabBar { // Hanya toggle jika belum disembunyikan, atau sesuaikan logikanya
                hideTabBar = true
            }
            setupQuiz() // Panggilan awal setupQuiz
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .navigationTitle("Kuis: \(kanjiSet.name)")
        .navigationBarTitleDisplayMode(.inline)
        .hideFloatingTabBar(hideTabBar) // Pastikan extension ini ada dan berfungsi
    }

    func setupQuiz() {
        isLoading = true
        isQuizFinished = false
        let sessionManager = QuizSessionManager.shared
        // Pastikan sesi diambil atau dibuat dengan benar
        let session = sessionManager.getOrCreateSession(for: kanjiSet, mode: .textInput, modelContext: modelContext)
        self.quizSession = session

        var orderedKanjis: [Kanji]
        if session.hasQuestionOrderSaved,
           let loadedOrder = sessionManager.loadQuizQuestionOrder(
               forQuizSessionId: session.sessionId,
               availableKanjis: kanjiSet.items,
               modelContext: modelContext
           ) {
            orderedKanjis = loadedOrder
        } else {
            orderedKanjis = kanjiSet.items.shuffled()
            sessionManager.saveQuizQuestionOrder(
                forQuizSessionId: session.sessionId,
                orderedKanjiIds: orderedKanjis.map { $0.id.uuidString },
                modelContext: modelContext
            )
            if !session.hasQuestionOrderSaved || session.currentQuestionIndex >= orderedKanjis.count {
                session.currentQuestionIndex = 0; session.score = 0; session.correctAnswers = 0; session.incorrectAnswers = 0; session.answeredQuestionIds = []
                // Tidak perlu save context di sini karena saveQuizQuestionOrder sudah melakukannya,
                // atau akan dilakukan di akhir getOrCreateSession.
            }
        }
        
        // Sinkronkan totalQuestions di session object dengan jumlah kanji yang akan di-generate soalnya (sebelum filter)
        // QuizSessionManager.getOrCreateSession sudah mengatur ini berdasarkan set.items.count
        // Blok ini mungkin untuk menangani perubahan pada orderedKanjis jika berbeda dari set.items.count
        if session.totalQuestions != orderedKanjis.count {
             session.totalQuestions = orderedKanjis.count
             if session.currentQuestionIndex >= session.totalQuestions && session.totalQuestions > 0 {
                 session.currentQuestionIndex = session.totalQuestions - 1
             } else if session.totalQuestions == 0 {
                 session.currentQuestionIndex = 0
             }
        }

        // <-- DIMODIFIKASI: Gunakan `hiraganaOnlyMode` saat generate soal -->
        self.allQuestions = QuizGenerator().generateAllTextInputQuestions(fromKanjis: orderedKanjis, hiraganaOnly: self.hiraganaOnlyMode)

        // Update totalQuestions di session agar sesuai dengan jumlah soal aktual setelah filter
        if session.totalQuestions != self.allQuestions.count {
            // print("Menyesuaikan total pertanyaan sesi dari \(session.totalQuestions) menjadi \(self.allQuestions.count) karena mode filter: \(self.hiraganaOnlyMode ? "Hiragana Saja" : "Campuran")")
            session.totalQuestions = self.allQuestions.count
            // Jika indeks saat ini di luar batas setelah jumlah soal berkurang
            if session.currentQuestionIndex >= session.totalQuestions {
                session.currentQuestionIndex = max(0, session.totalQuestions - 1)
            }
        }
        
        if self.allQuestions.isEmpty {
            isQuizFinished = true // Langsung selesai jika tidak ada soal yang bisa dibuat
            if !orderedKanjis.isEmpty { // Hanya tampilkan pesan jika memang ada kanji di set
                let modeInfo = self.hiraganaOnlyMode ? " (Mode Hiragana Saja)" : ""
                print("Tidak ada pertanyaan yang dapat dihasilkan\(modeInfo). Pastikan Kanji memiliki data yang sesuai atau ubah mode filter.")
            }
        } else {
             isQuizFinished = false // Ada soal, kuis belum selesai
        }

        // Logika untuk menentukan apakah kuis selesai atau lanjut ke pertanyaan berikutnya
        // Ini penting setelah session.totalQuestions mungkin diubah menjadi allQuestions.count
        if !self.allQuestions.isEmpty && session.currentQuestionIndex >= self.allQuestions.count {
             // Jika indeks saat ini (mungkin dari sesi lama) sudah melebihi jumlah soal baru
             session.currentQuestionIndex = self.allQuestions.count - 1 // Set ke soal terakhir yang valid
        }


        if session.currentQuestionIndex >= session.totalQuestions && session.totalQuestions > 0 {
            isQuizFinished = true
        } else if session.totalQuestions == 0 { // Jika tidak ada soal sama sekali
             isQuizFinished = true
        } else {
            updateCurrentQuestion()
        }
        
        // Pastikan perubahan pada session (seperti totalQuestions, currentQuestionIndex) disimpan jika perlu.
        // QuizSessionManager biasanya menangani penyimpanan saat update signifikan.
        // Untuk perubahan lokal seperti totalQuestions karena filter, mungkin tidak perlu save permanen
        // kecuali diinginkan. `restartQuiz` akan menyimpan perubahan state sesi yang di-reset.
        try? modelContext.save() // Simpan perubahan pada session jika ada.

        isLoading = false
    }

    func updateCurrentQuestion() {
        guard let unwrappedQuizSession = quizSession, !allQuestions.isEmpty else {
            currentQuestion = nil
            isQuizFinished = true // Jika tidak ada soal (allQuestions kosong), kuis selesai.
            return
        }

        if unwrappedQuizSession.currentQuestionIndex < allQuestions.count && unwrappedQuizSession.currentQuestionIndex < unwrappedQuizSession.totalQuestions {
            currentQuestion = allQuestions[unwrappedQuizSession.currentQuestionIndex]
            userAnswer = ""
            showFeedback = false
            isAnswerCorrect = nil
            // isQuizFinished = false // Tidak perlu di-set false di sini, karena bisa jadi ini soal terakhir
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
        } else {
            currentQuestion = nil
            isQuizFinished = true
        }
    }

    func checkAnswer() {
        guard let question = currentQuestion, let session = quizSession else { return }

        let trimmedUserAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        // Pertimbangkan normalisasi kana jika diperlukan (misalnya, Full-width vs Half-width)
        let isCorrect = trimmedUserAnswer.lowercased() == question.correctAnswerString.lowercased()

        self.isAnswerCorrect = isCorrect
        showFeedback = true

        let kanjiMeaning = question.kanjiSource.meaning.isEmpty ? "Tidak ada arti" : question.kanjiSource.meaning
        let kanjiCharacter = question.kanjiSource.kanji

        if isCorrect {
            feedbackMessage = "Benar! ✅\nArti \"\(kanjiCharacter)\": \(kanjiMeaning)"
        } else {
            feedbackMessage = "Salah. Jawaban: \(question.correctAnswerString)\nArti \"\(kanjiCharacter)\": \(kanjiMeaning)"
        }
        
        QuizSessionManager.shared.markQuestionAsAnswered(session: session, kanjiId: question.kanjiSource.id.uuidString, modelContext: modelContext)
        QuizSessionManager.shared.updateSession(session: session, answeredCorrectly: isCorrect, modelContext: modelContext)
    }

    func proceedToNextQuestionOrFinish() {
        guard let session = quizSession else { return }
        // Gunakan allQuestions.count sebagai batas atas yang sebenarnya untuk pertanyaan yang tersedia
        if session.currentQuestionIndex + 1 >= allQuestions.count {
            isQuizFinished = true
            isTextFieldFocused = false
        } else {
            QuizSessionManager.shared.incrementQuestionIndex(for: session, modelContext: modelContext)
            updateCurrentQuestion()
        }
    }
    
    func restartQuiz() {
        guard let session = quizSession else {
            // Jika sesi tidak ada, coba setup dari awal
            setupQuiz()
            return
        }
        session.currentQuestionIndex = 0
        session.score = 0
        session.correctAnswers = 0
        session.incorrectAnswers = 0
        session.answeredQuestionIds = []
        session.hasQuestionOrderSaved = false // Penting agar urutan soal di-generate ulang
        
        // Hapus urutan soal lama yang tersimpan
        QuizSessionManager.shared.clearQuizQuestionOrder(forQuizSessionId: session.sessionId, modelContext: modelContext, shouldSaveContext: false) // Jangan save dulu
        
        do {
            try modelContext.save() // Simpan perubahan reset pada sesi
        } catch {
            print("Error saat menyimpan sesi untuk restart Input Teks: \(error)")
        }
        // setupQuiz akan dipanggil dan menggunakan hiraganaOnlyMode yang baru
        setupQuiz()
    }
}
