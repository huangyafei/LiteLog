

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Text("LiteLLM Configuration")
                .font(.title2)
                .padding(.bottom)

            TextField("Base URL (e.g., https://litellm.example.com)", text: $viewModel.baseURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Admin API Key", text: $viewModel.adminApiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save") {
                    viewModel.saveSettings()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 450, height: 200)
        .onAppear {
            viewModel.loadSettings()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("LiteLog"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")) {
                if viewModel.alertMessage == "Settings saved successfully!" {
                    dismiss()
                }
            })
        }
    }
}

/*
#Preview {
    SettingsView()
}
*/

