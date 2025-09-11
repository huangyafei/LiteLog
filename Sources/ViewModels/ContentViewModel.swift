
import Foundation
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    @Published var virtualKeys: [VirtualKey] = []
    @Published var logEntries: [LogEntry] = []
    @Published var selectedKeyID: String? {
        didSet {
            UserDefaults.standard.set(selectedKeyID, forKey: lastSelectedKeyIDKey)
            if let key = virtualKeys.first(where: { $0.id == selectedKeyID }) {
                fetchLogs(for: key)
            }
        }
    }
    @Published var isLoadingKeys = false
    @Published var isLoadingLogs = false
    @Published var errorMessage: String?

    private var apiService: APIService?
    private let lastSelectedKeyIDKey = "LiteLogLastSelectedKeyID"
    private var logsCache: [String: [LogEntry]] = [:] // Cache for logs

    func setAPIService(_ apiService: APIService?) {
        self.apiService = apiService
        if apiService != nil {
            fetchKeys()
        } else {
            self.virtualKeys = []
            self.logEntries = []
            self.errorMessage = "Settings are not configured. Please configure them from the menu."
            self.logsCache = [:] // Clear cache if API service is reset
        }
    }

    func fetchKeys() {
        guard let apiService = apiService else { return }
        
        isLoadingKeys = true
        errorMessage = nil
        self.logsCache = [:] // Clear cache on full key refresh
        
        Task {
            do {
                let keys = try await apiService.fetchVirtualKeys()
                self.virtualKeys = keys
                
                // Restore last selection or select first key
                let lastID = UserDefaults.standard.string(forKey: lastSelectedKeyIDKey)
                if let lastID = lastID, keys.contains(where: { $0.id == lastID }) {
                    self.selectedKeyID = lastID
                } else if let firstKey = keys.first {
                    self.selectedKeyID = firstKey.id
                }

            } catch {
                print("Error fetching data: \(error)")
                self.errorMessage = error.localizedDescription
            }
            isLoadingKeys = false
        }
    }

    func fetchLogs(for key: VirtualKey) {
        // Check cache first
        if let cachedLogs = logsCache[key.token] {
            self.logEntries = cachedLogs
            return
        }

        guard let apiService = apiService else { return }
        
        isLoadingLogs = true
        errorMessage = nil
        self.logEntries = [] // Clear previous logs
        
        Task {
            do {
                let logs = try await apiService.fetchLogs(for: key.token)
                self.logEntries = logs
                self.logsCache[key.token] = logs // Store in cache
            } catch {
                print("Error fetching data: \(error)")
                self.errorMessage = error.localizedDescription
            }
            isLoadingLogs = false
        }
    }
    
    func manualRefresh() {
        if apiService != nil {
            self.logsCache = [:] // Clear cache on manual refresh
            fetchKeys()
        } 
    }
}
