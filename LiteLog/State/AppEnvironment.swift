import Foundation
import Combine

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}

@MainActor
class AppEnvironment: ObservableObject {
    // MARK: - Core App State
    @Published var apiService: APIService?
    @Published var virtualKeys: [VirtualKey] = []
    @Published var logsCache: [String: [LogEntry]] = [:]
    @Published var selectedKeyID: String? {
        didSet {
            UserDefaults.standard.set(selectedKeyID, forKey: lastSelectedKeyIDKey)
            if let key = virtualKeys.first(where: { $0.id == selectedKeyID }) {
                fetchLogs(for: key)
            }
        }
    }
    @Published var selectedLogEntryId: String?

    // MARK: - UI State
    @Published var isLoadingKeys = false
    @Published var isLoadingLogs = false
    @Published var isPaginating = false
    @Published var errorMessage: String?

    // MARK: - Private State
    private let lastSelectedKeyIDKey = "LiteLogLastSelectedKeyID"
    private var windowStartByToken: [String: Date] = [:]
    private var windowEndByToken: [String: Date] = [:]
    private let baseURLKey = "LiteLogBaseURL"
    private let apiKeyKey = "LiteLogAdminAPIKey"
    private let lookbackHoursKey = "LiteLogLookbackHours"
    private let pageSizeKey = "LiteLogPageSize"

    init() {
        loadApiService()
    }

    func loadApiService() {
        let baseURL = UserDefaults.standard.string(forKey: baseURLKey)
        let apiKey = UserDefaults.standard.string(forKey: apiKeyKey)

        if let baseURL = baseURL, !baseURL.isEmpty, let apiKey = apiKey, !apiKey.isEmpty {
            self.apiService = APIService(baseURL: baseURL, adminApiKey: apiKey)
            fetchKeys()
        } else {
            self.apiService = nil
            self.virtualKeys = []
            self.logsCache = [:]
            self.errorMessage = "Settings are not configured. Please configure them from the menu."
        }
    }
    
    // MARK: - Data Fetching Logic
    
    func fetchKeys() {
        guard let apiService = apiService else { return }
        
        isLoadingKeys = true
        errorMessage = nil
        self.logsCache = [:]
        self.windowStartByToken = [:]
        self.windowEndByToken = [:]
        
        Task {
            do {
                let keys = try await apiService.fetchVirtualKeys()
                self.virtualKeys = keys
                
                let lastID = UserDefaults.standard.string(forKey: lastSelectedKeyIDKey)
                if let lastID = lastID, keys.contains(where: { $0.id == lastID }) {
                    self.selectedKeyID = lastID
                } else if let firstKey = keys.first {
                    self.selectedKeyID = firstKey.id
                }

            } catch {
                print("Error fetching keys: \(error)")
                self.errorMessage = error.localizedDescription
            }
            isLoadingKeys = false
        }
    }

    func fetchLogs(for key: VirtualKey) {
        if let cachedLogs = logsCache[key.token] {
            // If cache exists, we assume it's valid for the current window.
            // No need to re-fetch unless explicitly refreshed.
            return
        }

        guard let apiService = apiService else { return }

        let hours = max(1, UserDefaults.standard.integer(forKey: lookbackHoursKey))
        let pageSize = max(10, UserDefaults.standard.integer(forKey: pageSizeKey))

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(TimeInterval(-hours * 3600))
        windowStartByToken[key.token] = startDate
        windowEndByToken[key.token] = endDate

        isLoadingLogs = true
        errorMessage = nil
        self.logsCache[key.token] = []

        Task {
            do {
                let logs = try await apiService.fetchLogs(for: key.token, startDate: startDate, endDate: endDate, pageSize: pageSize)
                self.logsCache[key.token] = logs
            } catch {
                print("Error fetching logs: \(error)")
                self.errorMessage = error.localizedDescription
            }
            isLoadingLogs = false
        }
    }

    func loadOlder() {
        guard let apiService = apiService,
              let selectedKeyID = selectedKeyID,
              let key = virtualKeys.first(where: { $0.id == selectedKeyID }) else { return }

        let hours = max(1, UserDefaults.standard.integer(forKey: lookbackHoursKey))
        let pageSize = max(10, UserDefaults.standard.integer(forKey: pageSizeKey))

        let currentStart = windowStartByToken[key.token] ?? Date().addingTimeInterval(TimeInterval(-hours * 3600))
        let newEnd = currentStart
        let newStart = newEnd.addingTimeInterval(TimeInterval(-hours * 3600))

        isPaginating = true
        errorMessage = nil

        Task {
            do {
                let olderLogs = try await apiService.fetchLogs(for: key.token, startDate: newStart, endDate: newEnd, pageSize: pageSize)
                
                var currentLogs = self.logsCache[key.token] ?? []
                let existingIDs = Set(currentLogs.map { $0.id })
                let filtered = olderLogs.filter { !existingIDs.contains($0.id) }
                
                currentLogs.append(contentsOf: filtered)
                self.logsCache[key.token] = currentLogs

                self.windowStartByToken[key.token] = newStart
                
            } catch {
                print("Error fetching older logs: \(error)")
                self.errorMessage = error.localizedDescription
            }
            isPaginating = false
        }
    }

    func resetToLatest() {
        guard let selectedKeyID = selectedKeyID,
              let key = virtualKeys.first(where: { $0.id == selectedKeyID }) else { return }

        logsCache[key.token] = nil
        windowStartByToken[key.token] = nil
        windowEndByToken[key.token] = nil

        fetchLogs(for: key)
    }
    
    func manualRefresh() {
        resetToLatest()
    }
    
    func refreshKeysAndLogs() {
        if apiService != nil {
            self.logsCache = [:]
            self.windowStartByToken = [:]
            self.windowEndByToken = [:]
            self.isPaginating = false
            fetchKeys()
        }
    }

    // MARK: - Computed Properties
    
    var currentLogEntries: [LogEntry] {
        guard let selectedKeyID = selectedKeyID else { return [] }
        return logsCache[selectedKeyID] ?? []
    }
}