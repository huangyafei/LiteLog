
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
    @Published var isPaginating = false
    @Published var errorMessage: String?

    private var apiService: APIService?
    private let lastSelectedKeyIDKey = "LiteLogLastSelectedKeyID"
    private var logsCache: [String: [LogEntry]] = [:] // Cache for logs per key (current loaded window)
    private var windowStartByToken: [String: Date] = [:]
    private var windowEndByToken: [String: Date] = [:]

    // Settings keys
    private let lookbackHoursKey = "LiteLogLookbackHours"
    private let pageSizeKey = "LiteLogPageSize"

    func setAPIService(_ apiService: APIService?) {
        self.apiService = apiService
        if apiService != nil {
            fetchKeys()
        } else {
            self.virtualKeys = []
            self.logEntries = []
            self.errorMessage = "Settings are not configured. Please configure them from the menu."
            self.logsCache = [:] // Clear cache if API service is reset
            self.windowStartByToken = [:]
            self.windowEndByToken = [:]
        }
    }

    func fetchKeys() {
        guard let apiService = apiService else { return }
        
        isLoadingKeys = true
        errorMessage = nil
        self.logsCache = [:] // Clear cache on full key refresh
        self.windowStartByToken = [:]
        self.windowEndByToken = [:]
        
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
        // If we have cached logs, use them
        if let cached = logsCache[key.token],
           let _ = windowStartByToken[key.token],
           let _ = windowEndByToken[key.token] {
            self.logEntries = cached
            return
        }

        guard let apiService = apiService else { return }

        // Load settings
        let hours = max(1, UserDefaults.standard.integer(forKey: lookbackHoursKey))
        let pageSize = max(10, UserDefaults.standard.integer(forKey: pageSizeKey))

        let endDate = Date()
        let startDate = endDate.addingTimeInterval(TimeInterval(-hours * 3600))
        windowStartByToken[key.token] = startDate
        windowEndByToken[key.token] = endDate

        isLoadingLogs = true
        errorMessage = nil
        self.logEntries = [] // Clear previous logs

        Task {
            do {
                let logs = try await apiService.fetchLogs(for: key.token, startDate: startDate, endDate: endDate, pageSize: pageSize)
                self.logEntries = logs
                self.logsCache[key.token] = logs // cache current window
            } catch {
                print("Error fetching data: \(error)")
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

                // Deduplicate by requestId
                let existingIDs = Set(self.logEntries.map { $0.id })
                let filtered = olderLogs.filter { !existingIDs.contains($0.id) }

                self.logEntries.append(contentsOf: filtered)
                self.logsCache[key.token] = self.logEntries

                // Slide window back
                self.windowStartByToken[key.token] = newStart
                self.windowEndByToken[key.token] = newEnd
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

        // Clear cached window for this key only
        logsCache[key.token] = nil
        windowStartByToken[key.token] = nil
        windowEndByToken[key.token] = nil

        fetchLogs(for: key)
    }
    
    func manualRefresh() {
        if apiService != nil {
            self.logsCache = [:] // Clear cache on manual refresh
            self.windowStartByToken = [:]
            self.windowEndByToken = [:]
            self.isPaginating = false
            fetchKeys()
        } 
    }
}
