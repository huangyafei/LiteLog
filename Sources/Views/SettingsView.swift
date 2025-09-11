

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Text("LiteLLM Configuration")
                .font(.title2)
                .padding(.bottom)

            TextField("Base URL", text: $viewModel.baseURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("API Key", text: $viewModel.adminApiKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Text("Your API Key is stored only on your local device and is not sent to the application developer.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
                .fixedSize(horizontal: false, vertical: true)
            
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
        .frame(maxHeight: 250)
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

