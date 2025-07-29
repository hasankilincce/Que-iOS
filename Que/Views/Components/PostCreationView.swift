import SwiftUI

struct PostCreationView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @ObservedObject var mediaCaptureManager: MediaCaptureManager
    
    @State private var availableQuestions: [Post] = []
    @State private var isLoadingQuestions = false
    
    let onCancel: () -> Void
    let onPost: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button("İptal") {
                    onCancel()
                }
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .medium))
                
                Spacer()
                
                Text("Gönderi Oluştur")
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .semibold))
                
                Spacer()
                
                Button("Paylaş") {
                    onPost()
                }
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
                .disabled(viewModel.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 20)
            
            // Content area
            ScrollView {
                VStack(spacing: 20) {
                    // Post type selector
                    HStack {
                        Text("Gönderi Türü")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Picker("Gönderi Türü", selection: $viewModel.selectedPostType) {
                            Text("Soru").tag(PostType.question)
                            Text("Cevap").tag(PostType.answer)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                    .padding(.horizontal, 20)
                    
                    // Parent question selector (for answers)
                    if viewModel.selectedPostType == .answer {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hangi Soruya Cevap Veriyorsunuz?")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .medium))
                            
                            if let selectedQuestion = viewModel.selectedParentQuestion {
                                HStack {
                                    Text(selectedQuestion.content)
                                        .foregroundColor(.white)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Button("Değiştir") {
                                        viewModel.selectedParentQuestion = nil
                                    }
                                    .foregroundColor(.blue)
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            } else {
                                Button("Soru Seç") {
                                    loadAvailableQuestions()
                                }
                                .foregroundColor(.blue)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Content text field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("İçerik")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField("Gönderinizi yazın...", text: $viewModel.content, axis: .vertical)
                            .textFieldStyle(PlainTextFieldStyle())
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                            .lineLimit(5...10)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 20)
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .sheet(isPresented: $isLoadingQuestions) {
            QuestionSelectionView(
                questions: availableQuestions,
                selectedQuestion: $viewModel.selectedParentQuestion
            )
        }
    }
    
    private func loadAvailableQuestions() {
        // TODO: Load available questions from Firestore
        isLoadingQuestions = true
    }
}

// MARK: - Question Selection View
struct QuestionSelectionView: View {
    let questions: [Post]
    @Binding var selectedQuestion: Post?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(questions) { question in
                Button(action: {
                    selectedQuestion = question
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.content)
                            .foregroundColor(.primary)
                            .lineLimit(3)
                        
                        Text("@\(question.username)")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Soru Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
} 