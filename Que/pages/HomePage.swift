import SwiftUI

struct HomePage: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showProfile = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Hoşgeldin, \(viewModel.displayName)")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 40)
                Button(action: {
                    viewModel.signOut()
                }) {
                    Text("Çıkış Yap")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle")
                            .font(.title)
                    }
                }
            }
            .navigationDestination(isPresented: $showProfile) {
                ProfilePage()
            }
        }
    }
}

#Preview {
    HomePage()
} 