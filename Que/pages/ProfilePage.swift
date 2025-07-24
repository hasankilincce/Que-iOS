import SwiftUI
import SDWebImageSwiftUI

struct ProfilePage: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var showEdit = false
    
    init(userId: String? = nil) {
        _viewModel = StateObject(wrappedValue: ProfileViewModel(userId: userId))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                } else {
                    if let urlString = viewModel.photoURL, let url = URL(string: urlString), !urlString.isEmpty {
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
                    Text(viewModel.displayName.isEmpty ? "Kullanıcı" : viewModel.displayName)
                        .font(.largeTitle)
                        .bold()
                    Text(viewModel.email)
                        .foregroundColor(.gray)
                    if viewModel.isCurrentUser {
                        Button("Profili Düzenle") {
                            showEdit = true
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button("Takip Et") {
                            // Takip et akışı (ileride)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $showEdit) {
                EditProfilePage(userId: viewModel.userId)
            }
        }
    }
}

#Preview {
    ProfilePage()
} 