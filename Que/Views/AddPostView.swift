import SwiftUI
import PhotosUI
import TOCropViewController

struct AddPostView: View {
    @ObservedObject var viewModel: AddPostViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    postTypeSelectorView
                    parentQuestionSelectorView
                    contentInputView
                    backgroundImageView
                    messageViews
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Yeni Gönderi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Paylaş") {
                        Task {
                            await viewModel.createPost()
                            if viewModel.successMessage != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.canPost)
                    .foregroundColor(viewModel.canPost ? .purple : .gray)
                }
            }
            .sheet(isPresented: $viewModel.showImagePicker) {
                BackgroundImagePicker { image in
                    viewModel.setBackgroundImage(image)
                }
            }
            .sheet(isPresented: $viewModel.showCamera) {
                CameraView { image in
                    viewModel.setBackgroundImage(image)
                }
            }
            .overlay {
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var postTypeSelectorView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gönderi Tipi")
                .font(.headline)
            
            HStack(spacing: 12) {
                ForEach(PostType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.changePostType(to: type)
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                            Text(type.displayName)
                        }
                        .foregroundColor(viewModel.selectedPostType == type ? .white : .purple)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            viewModel.selectedPostType == type ? 
                            Color.purple : Color.purple.opacity(0.1)
                        )
                        .cornerRadius(20)
                    }
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    private var parentQuestionSelectorView: some View {
        if viewModel.selectedPostType == .answer {
            VStack(alignment: .leading, spacing: 12) {
                Text("Hangi Soruya Cevap Veriyorsunuz?")
                    .font(.headline)
                
                if viewModel.isLoadingQuestions {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Sorular yükleniyor...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else if viewModel.availableQuestions.isEmpty {
                    emptyQuestionsView
                } else {
                    questionsScrollView
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyQuestionsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "questionmark.circle")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text("Henüz cevaplanabilir soru bulunmuyor")
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Soruları Yenile") {
                Task {
                    await viewModel.loadAvailableQuestions()
                }
            }
            .font(.caption)
            .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var questionsScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.availableQuestions) { question in
                    QuestionCard(
                        question: question,
                        isSelected: viewModel.selectedParentQuestion?.id == question.id
                    ) {
                        viewModel.selectParentQuestion(question)
                    }
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 120)
    }
    
    @ViewBuilder
    private var contentInputView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(viewModel.selectedPostType == .question ? "Sorunuz nedir?" : "Cevabınız nedir?")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.remainingCharacters)")
                    .font(.caption)
                    .foregroundColor(viewModel.remainingCharacters < 0 ? .red : .secondary)
            }
            
            TextEditor(text: $viewModel.content)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.remainingCharacters < 0 ? Color.red : Color.clear, lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    private var backgroundImageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Arkaplan Fotoğrafı (9:16)")
                .font(.headline)
            
            if let backgroundImage = viewModel.backgroundImage {
                selectedImageView(backgroundImage)
            } else {
                imageSelectionView
            }
        }
    }
    
    @ViewBuilder
    private func selectedImageView(_ image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 320) // 9:16 dikey format için daha yüksek
                .clipped()
                .cornerRadius(12)
            
            Button(action: {
                viewModel.removeBackgroundImage()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
    
    @ViewBuilder
    private var imageSelectionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("9:16 oranında arkaplan fotoğrafı ekleyin")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo")
                        Text("Galeri")
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(20)
                }
                
                Button(action: {
                    viewModel.showCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera")
                        Text("Kamera")
                    }
                    .foregroundColor(.purple)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(20)
                }
            }
        }
        .frame(height: 320)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var messageViews: some View {
        VStack(spacing: 12) {
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            }
            
            if let success = viewModel.successMessage {
                Text(success)
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                
                Text("Gönderi paylaşılıyor...")
                    .foregroundColor(.white)
                    .font(.subheadline)
            }
            .padding(24)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
        }
    }
}

// Question card component for parent selection
struct QuestionCard: View {
    let question: Post
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("@\(question.username)")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .secondary)
                }
                
                Text(question.content)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(12)
            .frame(width: 200, height: 100)
            .background(
                isSelected ? Color.green.opacity(0.1) : Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
            )
        }
    }
}

// Background image picker with cropping functionality
struct BackgroundImagePicker: UIViewControllerRepresentable {
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate, TOCropViewControllerDelegate {
        let parent: BackgroundImagePicker
        
        init(_ parent: BackgroundImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            if let result = results.first {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self.showCropViewController(with: image, from: picker)
                            }
                        }
                    }
                }
            } else {
                parent.dismiss()
            }
        }
        
        private func showCropViewController(with image: UIImage, from presentingController: UIViewController) {
            let cropViewController = TOCropViewController(croppingStyle: .default, image: image)
            cropViewController.delegate = self
            
            // 9:16 aspect ratio için ayarlama
            cropViewController.aspectRatioPreset = .presetCustom
            cropViewController.customAspectRatio = CGSize(width: 9, height: 16)
            cropViewController.aspectRatioLockEnabled = true
            cropViewController.resetAspectRatioEnabled = false
            cropViewController.aspectRatioPickerButtonHidden = true
            
            // Crop view styling
            cropViewController.title = "Fotoğrafı Kırp"
            cropViewController.doneButtonTitle = "Tamam"
            cropViewController.cancelButtonTitle = "İptal"
            
            presentingController.present(cropViewController, animated: true)
        }
        
        // MARK: - TOCropViewControllerDelegate
        
        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onImageSelected(image)
            cropViewController.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
    }
}

// Camera wrapper with cropping functionality
struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate, TOCropViewControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                showCropViewController(with: image, from: picker)
            } else {
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
        
        private func showCropViewController(with image: UIImage, from presentingController: UIViewController) {
            let cropViewController = TOCropViewController(croppingStyle: .default, image: image)
            cropViewController.delegate = self
            
            // 9:16 aspect ratio için ayarlama
            cropViewController.aspectRatioPreset = .presetCustom
            cropViewController.customAspectRatio = CGSize(width: 9, height: 16)
            cropViewController.aspectRatioLockEnabled = true
            cropViewController.resetAspectRatioEnabled = false
            cropViewController.aspectRatioPickerButtonHidden = true
            
            // Crop view styling
            cropViewController.title = "Fotoğrafı Kırp"
            cropViewController.doneButtonTitle = "Tamam"
            cropViewController.cancelButtonTitle = "İptal"
            
            presentingController.present(cropViewController, animated: true)
        }
        
        // MARK: - TOCropViewControllerDelegate
        
        func cropViewController(_ cropViewController: TOCropViewController, didCropTo image: UIImage, with cropRect: CGRect, angle: Int) {
            parent.onImageCaptured(image)
            cropViewController.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
        
        func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
            cropViewController.dismiss(animated: true) {
                self.parent.dismiss()
            }
        }
    }
} 