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
        .fullScreenCover(isPresented: $showImagePicker) {
            UIKitCropImagePicker(image: $selectedImage, isPresented: $showImagePicker)
                .onDisappear {
                    if let image = selectedImage {
                        viewModel.selectProfilePhoto(image)
                    }
                }
        }
    }
}
