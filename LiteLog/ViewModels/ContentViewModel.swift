import Foundation
import Combine

@MainActor
class ContentViewModel: ObservableObject {
    // Environment
    private var appEnvironment: AppEnvironment

    // UI State
    @Published var focusedLogEntryId: String?
    
    private var cancellables = Set<AnyCancellable>()

    init(appEnvironment: AppEnvironment) {
        self.appEnvironment = appEnvironment
    }

    // MARK: - Keyboard Navigation
    
    func moveFocus(down: Bool) {
        let logs = appEnvironment.currentLogEntries
        guard !logs.isEmpty else { return }
        
        let currentIndex: Int
        let startId = focusedLogEntryId ?? appEnvironment.selectedLogEntryId
        if let startId = startId, let index = logs.firstIndex(where: { $0.id == startId }) {
            currentIndex = index
        } else {
            focusedLogEntryId = down ? logs.first?.id : logs.last?.id
            return
        }
        
        let nextIndex = down ? logs.index(after: currentIndex) : logs.index(before: currentIndex)
        
        if nextIndex >= logs.startIndex && nextIndex < logs.endIndex {
            focusedLogEntryId = logs[nextIndex].id
        }
    }
    
    func selectFocusedItem() {
        if let focusedLogEntryId = focusedLogEntryId {
            appEnvironment.selectedLogEntryId = focusedLogEntryId
        }
    }
    
    func clearFocus() {
        focusedLogEntryId = nil
    }
}