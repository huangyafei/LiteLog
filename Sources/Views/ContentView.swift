
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject private var appEnvironment: AppEnvironment
    
    @State private var selectedLogID: LogEntry.ID?

    var body: some View {
        VStack(alignment: .leading) {
            NavigationSplitView {
                sidebar
            } content: {
                logList
            } detail: {
                LogDetailView(log: selectedLog)
            }
            
            if let errorMessage = viewModel.errorMessage {
                errorFooter(errorMessage)
            }
        }
        .navigationTitle("LiteLog")
        .toolbar {
            ToolbarItem {
                Button(action: { viewModel.manualRefresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .help("Refresh API Keys and Logs")
            }
        }
        
        .onReceive(appEnvironment.$apiService) { newAPIService in
            viewModel.setAPIService(newAPIService)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        if viewModel.isLoadingKeys {
            ProgressView("Loading Keys...")
        } else if viewModel.virtualKeys.isEmpty {
            Text("No API Keys found.")
                .foregroundColor(.secondary)
        } else {
            List(viewModel.virtualKeys, selection: $viewModel.selectedKeyID) {
                key in
                VStack(alignment: .leading) {
                    Text(key.keyAlias ?? key.keyName).font(.headline)
                    Text("\(String(format: "%.4f", key.spend)) USD").font(.caption)
                }
                .tag(key.id)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250)
        }
    }

    @ViewBuilder
    private var logList: some View {
        if viewModel.isLoadingLogs {
            ProgressView("Loading Logs...")
        } else if let selectedKeyID = viewModel.selectedKeyID, !selectedKeyID.isEmpty, viewModel.logEntries.isEmpty {
            Text("No logs for this key.")
                .foregroundColor(.secondary)
        } else {
            List(viewModel.logEntries, selection: $selectedLogID) {
                log in
                LogEntryRowView(log: log)
            }
        }
    }
    
    private var selectedLog: LogEntry? {
        guard let selectedLogID = selectedLogID else { return nil }
        return viewModel.logEntries.first { $0.id == selectedLogID }
    }
    
    private func errorFooter(_ message: String) -> some View {
        HStack {
            Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
            Text(message)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
    }
}

/*
#Preview {
    ContentView()
}
*/
