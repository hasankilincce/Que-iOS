import SwiftUI
import SDWebImageSwiftUI
import TOCropViewController


struct OnboardingProfilePage: View {
    @StateObject private var viewModel = OnboardingProfileViewModel()
    @State private var step: Int = 0
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @EnvironmentObject var appState: AppState

    let steps = ["Görünecek Ad", "Profil Fotoğrafı", "Biyografi"]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(i == step ? Color.purple : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 32)
                Spacer()
                Text(steps[step])
                    .font(.title.bold())
                    .padding(.bottom, 8)
                if step == 0 {
                    Text("Profilinde görünecek adını belirle.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    TextField("Görünecek ad", text: $viewModel.displayName)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 32)
                } else if step == 1 {
                    Text("Profil fotoğrafı ekle veya değiştir.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    ZStack {
                        if let image = viewModel.localProfileImage {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 140, height: 140)
                                .clipShape(Circle())
                                .shadow(radius: 8)
                                .transition(.scale)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 140, height: 140)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray)
                                )
                        }
                        Button(action: { showImagePicker = true }) {
                            Circle()
                                .fill(LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "plus")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                )
                                .shadow(radius: 4)
                        }
                        .offset(x: 50, y: 50)
                    }
                } else if step == 2 {
                    Text("Kendini kısaca tanıtabilirsin (isteğe bağlı).")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 24)
                    TextEditor(text: $viewModel.bio)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                }
                Spacer()
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding(.bottom, 8)
                }
                HStack {
                    if step > 0 {
                        Button(action: { withAnimation { step -= 1 } }) {
                            Image(systemName: "chevron.left")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 24)
                    }
                    Spacer()
                    if step < 2 {
                        Button(action: { withAnimation { step += 1 } }) {
                            Text("Devam")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 120, height: 44)
                                .background(
                                    LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .cornerRadius(22)
                        }
                        .padding(.trailing, 24)
                        .disabled(viewModel.displayName.trimmingCharacters(in: .whitespaces).isEmpty && step == 0)
                    } else {
                        Button(action: {
                            Task {
                                await viewModel.saveProfile()
                                appState.needsOnboarding = false
                            }
                        }) {
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("Başla")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(width: 120, height: 44)
                                    .background(
                                        LinearGradient(colors: [Color.purple, Color.pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .cornerRadius(22)
                            }
                        }
                        .padding(.trailing, 24)
                        Button("Atla") {
                            appState.needsOnboarding = false
                        }
                        .foregroundColor(.gray)
                        .padding(.trailing, 8)
                    }
                }
                .padding(.bottom, 32)
            }
            .fullScreenCover(isPresented: $showImagePicker) {
                UIKitCropImagePicker(image: $selectedImage, isPresented: $showImagePicker)
                    .onDisappear {
                        if let image = selectedImage {
                            viewModel.selectProfilePhoto(image)
                        }
                    }
            }
            .onChange(of: viewModel.success) { newValue in
                if newValue {
                    appState.needsOnboarding = false
                }
            }
        }
    }
} 
