
import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var baseURL: String = ""
    @Published var adminApiKey: String = ""
    
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let baseURLKey = "LiteLogBaseURL"
    private let apiKeyKey = "LiteLogAdminAPIKey"

    init() {
        loadSettings()
    }

    func loadSettings() {
        self.baseURL = UserDefaults.standard.string(forKey: baseURLKey) ?? ""
        self.adminApiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
    }

    func saveSettings() {
        guard !baseURL.isEmpty, !adminApiKey.isEmpty else {
            self.alertMessage = "Base URL and Admin API Key cannot be empty."
            self.showAlert = true
            return
        }
        
        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
        UserDefaults.standard.set(adminApiKey, forKey: apiKeyKey)
        
        self.alertMessage = "Settings saved successfully!"
        self.showAlert = true
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
}
