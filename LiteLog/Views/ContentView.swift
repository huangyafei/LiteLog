import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                NavigationSplitView {
                    SidebarView()
                } content: {
                    LogListView(viewModel: viewModel)
                } detail: {
                    LogDetailView(log: selectedLog)
                }
                
                if let errorMessage = appEnvironment.errorMessage {
                    errorFooter(errorMessage)
                }
            }
        }
        .navigationTitle("LiteLog")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()

                Button(action: { appEnvironment.manualRefresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(LinearButtonStyle(variant: .ghost))
                .help("Refresh Logs")
            }
        }
    }
    
    private var selectedLog: LogEntry? {
        guard let selectedLogID = appEnvironment.selectedLogEntryId else { return nil }
        return appEnvironment.currentLogEntries.first { $0.id == selectedLogID }
    }
    
    private func errorFooter(_ message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(DesignSystem.Colors.error)
                .font(.system(size: 14))
            
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.error)
            
            Spacer()
            
            Button("Dismiss") {
                appEnvironment.errorMessage = nil
            }
            .buttonStyle(LinearButtonStyle(variant: .ghost))
            .foregroundColor(DesignSystem.Colors.error)
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.errorBackground)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(DesignSystem.Colors.border),
            alignment: .top
        )
    }
}