
import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var baseURL: String = ""
    @Published var adminApiKey: String = ""
    @Published var lookbackHours: Int = 24
    @Published var pageSize: Int = 50
    
    @Published var showAlert = false
    @Published var alertMessage = ""

    private let baseURLKey = "LiteLogBaseURL"
    private let apiKeyKey = "LiteLogAdminAPIKey"
    private let lookbackKey = "LiteLogLookbackHours"
    private let pageSizeKey = "LiteLogPageSize"

    init() {
        loadSettings()
    }

    func loadSettings() {
        self.baseURL = UserDefaults.standard.string(forKey: baseURLKey) ?? ""
        self.adminApiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        let hours = UserDefaults.standard.integer(forKey: lookbackKey)
        self.lookbackHours = hours == 0 ? 24 : hours
        let size = UserDefaults.standard.integer(forKey: pageSizeKey)
        self.pageSize = size == 0 ? 50 : size
    }

    func saveSettings() {
        guard !baseURL.isEmpty, !adminApiKey.isEmpty else {
            self.alertMessage = "Base URL and Admin API Key cannot be empty."
            self.showAlert = true
            return
        }
        
        // Clamp values to sane ranges
        let clampedHours = max(1, min(168, lookbackHours)) // 1h..7d
        let clampedPage = max(10, min(500, pageSize))

        UserDefaults.standard.set(baseURL, forKey: baseURLKey)
        UserDefaults.standard.set(adminApiKey, forKey: apiKeyKey)
        UserDefaults.standard.set(clampedHours, forKey: lookbackKey)
        UserDefaults.standard.set(clampedPage, forKey: pageSizeKey)

        self.alertMessage = "Settings saved successfully!"
        self.showAlert = true
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }
}
