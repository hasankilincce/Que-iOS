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
        VStack(spacing: 0) {
            // Custom üst bar (profildeki ayarlar ile aynı hiza)
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(8)
                }
                Spacer()
                Text("Profili Düzenle")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                // Sağda boşluk, ayarlar butonu ile aynı hiza için
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .overlay(
                EmptyView().navigationBarBackButtonHidden(true)
            )
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // Profil fotoğrafı
                    ZStack(alignment: .bottomTrailing) {
                        if let image = viewModel.localProfileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else if let url = URL(string: viewModel.photoURL), !viewModel.photoURL.isEmpty {
                            WebImage(url: url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 96, height: 96)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 96, height: 96)
                                .foregroundColor(.gray.opacity(0.4))
                        }
                        Button(action: { showImagePicker = true }) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.purple)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                        }
                        .offset(x: 4, y: 4)
                    }
                    .padding(.top, 12)
                    // Alanlar
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Ad")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Ad", text: $viewModel.displayName)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Kullanıcı Adı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Kullanıcı Adı", text: $viewModel.username)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Biyografi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("Biyografi", text: $viewModel.bio, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(1...3)
                        }
                    }
                    .padding(.horizontal)
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                    if let success = viewModel.successMessage {
                        Text(success)
                            .foregroundColor(.green)
                            .font(.footnote)
                    }
                }
                .padding(.bottom, 120)
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(action: {
                    viewModel.saveProfile {
                        dismiss()
                    }
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text("Kaydet")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground).opacity(0.95))
        }
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
