import SwiftUI
import AVFoundation

struct PostCreationView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @ObservedObject var mediaCaptureManager: MediaCaptureManager
    
    @State private var availableQuestions: [Post] = []
    @State private var isLoadingQuestions = false
    @FocusState private var isTextFieldFocused: Bool
    
    let onCancel: () -> Void
    let onPost: () -> Void
    
    // Computed properties to simplify the view
    private var backgroundView: some View {
        Group {
            if let image = mediaCaptureManager.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else if let videoURL = mediaCaptureManager.capturedVideoURL {
                // Custom Video Player
                CustomVideoPlayerView(videoURL: videoURL)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .onAppear {
                        // PostCreationView açıldığında ses ayarlarını kontrol et
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                            try AVAudioSession.sharedInstance().setActive(true)
                        } catch {
                            print("PostCreationView ses ayarları hatası: \(error)")
                        }
                    }
            } else {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.8),
                        Color.purple.opacity(0.6),
                        Color.pink.opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .onTapGesture {
            // Medya alanına tıklayınca klavyeyi kapat
            hideKeyboard()
        }
    }
    
    private var postTypeBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.selectedPostType.icon)
                .font(.caption.weight(.semibold))
            Text(viewModel.selectedPostType.displayName)
                .font(.caption.weight(.bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
    }
    
    private var contentTextField: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: $viewModel.content, axis: .vertical)
                .font(.system(size: 24, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1...6)
                .multilineTextAlignment(.leading)
                .focused($isTextFieldFocused)
                .onChange(of: viewModel.content) { newValue in
                    //print("[DEBUG] TextField content changed: \(newValue)")
                    // Satır sayısı kontrolü
                    let lines = newValue.components(separatedBy: .newlines)
                    if lines.count > 4 {
                        //print("[DEBUG] Satır limiti aşıldı, kesiliyor.")
                        let limitedLines = Array(lines.prefix(4))
                        viewModel.content = limitedLines.joined(separator: "\n")
                        return
                    }
                    // Karakter sayısı kontrolü
                    if newValue.count > viewModel.maxContentLength {
                        //print("[DEBUG] Karakter limiti aşıldı, kesiliyor.")
                        let index = newValue.index(newValue.startIndex, offsetBy: viewModel.maxContentLength)
                        viewModel.content = String(newValue[..<index])
                    }
                }
                .onChange(of: isTextFieldFocused) { focused in
                    //print("[DEBUG] TextField focus changed: \(focused)")
                }
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                .padding(.horizontal, 4)
                .overlay(
                    Group {
                        if viewModel.content.isEmpty && !isTextFieldFocused {
                            HStack {
                                Text("Buraya sorunu yaz...")
                                    .font(.system(size: 24, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(4)
                                    .multilineTextAlignment(.leading)
                                    .allowsHitTesting(false) // Tıklamayı TextField'a geçir
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                )
                .onChange(of: viewModel.content) { _ in
                    if viewModel.content.isEmpty {
                        isTextFieldFocused = false
                    }
                }
                .onTapGesture {
                    print("[DEBUG] TextField tapped!")
                }
            
            HStack {
                Text("\(viewModel.content.count)/\(viewModel.maxContentLength)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var parentQuestionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hangi Soruya Cevap Veriyorsunuz?")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
            
            if let selectedQuestion = viewModel.selectedParentQuestion {
                HStack {
                    Text(selectedQuestion.content)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button("Değiştir") {
                        viewModel.selectedParentQuestion = nil
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                Button("Soru Seç") {
                    loadAvailableQuestions()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [.green, .teal], 
                                           startPoint: .leading, endPoint: .trailing))
                )
                .shadow(color: .green.opacity(0.4), radius: 4, x: 0, y: 2)
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(alignment: .bottom) {
            Button("İptal") {
                onCancel()
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 3)
            
            Spacer()
            
            Button("Paylaş") {
                onPost()
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        viewModel.canPost ? 
                        LinearGradient(colors: [.green, .teal], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [.gray.opacity(0.6), .gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                    )
            )
            .shadow(color: viewModel.canPost ? .green.opacity(0.4) : .black.opacity(0.4), radius: 6, x: 0, y: 3)
            .disabled(!viewModel.canPost || viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // Overlay gradients removed
                
                // Content - Feed style layout
                VStack(spacing: 0) {
                    // Top area - Text content with Post Type Badge and Text Input (Feed style)
                    VStack {
                        Spacer()
                            .frame(height: geometry.safeAreaInsets.top + 80) // More space for status bar and notch
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 12) {
                                // Post type badge
                                postTypeBadge
                                
                                // Text input area
                                contentTextField
                                
                                // Question selector (only for answers)
                                if viewModel.selectedPostType == .answer {
                                    parentQuestionSelector
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.trailing, 20) // Space for right side
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer()
                    }
                    
                    // Bottom area - Action buttons
                    actionButtons
                        .frame(height: 120)
                }
                .onTapGesture {
                    // Klavyeyi kapatmak için boş alana tıklama
                    hideKeyboard()
                }
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .sheet(isPresented: $isLoadingQuestions) {
            QuestionSelectionView(
                questions: availableQuestions,
                selectedQuestion: $viewModel.selectedParentQuestion
            )
        }
        .overlay(
            Group {
                if viewModel.isVideoProcessing {
                    VStack(spacing: 20) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Video işleniyor...")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Bu işlem birkaç dakika sürebilir")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 14))
                    }
                    .padding(30)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(15)
                }
            }
        )
    }
    
    private func loadAvailableQuestions() {
        isLoadingQuestions = true
    }
    
    // Klavye kapatma fonksiyonu
    private func hideKeyboard() {
        isTextFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
