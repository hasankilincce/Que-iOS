import SwiftUI

struct ResetPasswordPage: View {
    @StateObject private var viewModel = ResetPasswordViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Şifre Sıfırla")
                .font(.largeTitle)
                .bold()
                .padding(.top, 40)
            TextField("Email", text: $viewModel.email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            if let info = viewModel.infoMessage {
                Text(info)
                    .foregroundColor(.green)
            }
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Button(action: {
                viewModel.resetPassword()
            }) {
                Text("Şifre Sıfırla")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isLoading)
            Button("Girişe Dön") {
                dismiss()
            }
            Spacer()
        }
        .padding()
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        )
    }
}

#Preview {
    ResetPasswordPage()
} 