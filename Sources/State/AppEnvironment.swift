
import Foundation
import Combine

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

@MainActor
class AppEnvironment: ObservableObject {
    @Published var apiService: APIService?

    private let baseURLKey = "LiteLogBaseURL"
    private let apiKeyKey = "LiteLogAdminAPIKey"

    init() {
        loadApiService()
    }

    func loadApiService() {
        let baseURL = UserDefaults.standard.string(forKey: baseURLKey)
        let apiKey = UserDefaults.standard.string(forKey: apiKeyKey)

        if let baseURL = baseURL, !baseURL.isEmpty, let apiKey = apiKey, !apiKey.isEmpty {
            self.apiService = APIService(baseURL: baseURL, adminApiKey: apiKey)
        } else {
            self.apiService = nil
        }
    }
}
