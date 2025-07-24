import SwiftUI
import PhotosUI
import SDWebImageSwiftUI
import TOCropViewController

struct EditProfilePage: View {
    @StateObject private var viewModel: EditProfileViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    
    init(userId: String) {
        _viewModel = StateObject(wrappedValue: EditProfileViewModel(userId: userId))
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Profili Düzenle")
                .font(.title)
                .bold()
            ZStack(alignment: .bottomTrailing) {
                if let image = viewModel.localProfileImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else if let url = URL(string: viewModel.photoURL), !viewModel.photoURL.isEmpty {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .background(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        )
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                }
                Button(action: {
                    showImagePicker = true
                }) {
                    Image(systemName: "camera.fill")
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 8, y: 8)
            }
            TextField("Kullanıcı Adı", text: $viewModel.displayName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Profil Fotoğrafı URL", text: $viewModel.photoURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            if let success = viewModel.successMessage {
                Text(success)
                    .foregroundColor(.green)
            }
            Button(action: {
                viewModel.saveProfile {
                    dismiss()
                }
            }) {
                if viewModel.isLoading {
                    ProgressView()
                } else {
                    Text("Kaydet")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .disabled(viewModel.isLoading)
            Spacer()
        }
        .padding()
        .sheet(isPresented: $showImagePicker) {
            CropImagePicker(image: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        viewModel.selectProfilePhoto(image)
                    }
                }
        }
    }
}

// CropViewController destekli ImagePicker
struct CropImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate, TOCropViewControllerDelegate {
        let parent: CropImagePicker
        var pickedImage: UIImage?
        
        init(_ parent: CropImagePicker) { self.parent = parent }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                pickedImage = uiImage
                let cropVC = TOCropViewController(croppingStyle: .circular, image: uiImage)
                cropVC.delegate = self
                picker.present(cropVC, animated: true)
            } else {
                picker.dismiss(animated: true)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
        
        // TOCropViewControllerDelegate
        func cropViewController(_ cropViewController: TOCropViewController, didCropToCircularImage image: UIImage, with cropRect: CGRect, angle: Int) {
            // Boyut küçültme
            let resized = image.resize(to: CGSize(width: 256, height: 256))
            parent.image = resized
            cropViewController.dismiss(animated: true) {
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

// UIImage boyut küçültme extension
extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
