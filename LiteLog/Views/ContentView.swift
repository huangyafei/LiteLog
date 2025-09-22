import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.openWindow) var openWindow
    
    @State private var selectedLogID: LogEntry.ID?
    @State private var isAtTop: Bool = true
    @State private var isAtBottom: Bool = false
    

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
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
        }
        .navigationTitle("LiteLog")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Spacer()

                Button(action: { viewModel.manualRefresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .buttonStyle(LinearButtonStyle(variant: .ghost))
                .help("Refresh API Keys and Logs")
            }
        }
        
        .onReceive(appEnvironment.$apiService) { newAPIService in
            viewModel.setAPIService(newAPIService)
        }
    }

    @ViewBuilder
    private var sidebar: some View {
        ZStack {
            DesignSystem.Colors.backgroundSecondary
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("API Keys")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: { viewModel.refreshKeysAndLogs() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(LinearButtonStyle(variant: .ghost))
                    .help("Refresh API Key list")
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Content
                if viewModel.isLoadingKeys {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                        Text("Loading Keys...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, DesignSystem.Spacing.sm)
                        Spacer()
                    }
                } else if viewModel.virtualKeys.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "key")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("No API Keys found")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, DesignSystem.Spacing.sm)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignSystem.Spacing.xs) {
                            ForEach(viewModel.virtualKeys) { key in
                                KeyRowView(
                                    key: key, 
                                    isSelected: viewModel.selectedKeyID == key.id
                                ) {
                                    viewModel.selectedKeyID = key.id
                                }
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                }
                
                Spacer()
                
                // Footer
                Divider()
                    .background(DesignSystem.Colors.border)
                
                HStack {
                    Button(action: { openWindow(id: "settings") }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                            Text("Settings")
                                .font(DesignSystem.Typography.body)
                        }
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(LinearButtonStyle(variant: .ghost))
                    .help("Settings")
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
            }
        }
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
    }

    @ViewBuilder
    private var logList: some View {
        ZStack {
            DesignSystem.Colors.backgroundTertiary
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Logs")
                        .font(DesignSystem.Typography.titleSmall)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    if !viewModel.logEntries.isEmpty {
                        Text("\(viewModel.logEntries.count) entries")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Content
                if viewModel.isLoadingLogs {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                        Text("Loading Logs...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, DesignSystem.Spacing.sm)
                        Spacer()
                    }
                } else if let selectedKeyID = viewModel.selectedKeyID, !selectedKeyID.isEmpty, viewModel.logEntries.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.text")
                            .font(.system(size: 24))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        Text("No logs for this key")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.top, DesignSystem.Spacing.sm)
                        Spacer()
                    }
                } else {
                    ScrollViewReader { proxy in
                        ZStack {
                            ScrollView {
                                LazyVStack(spacing: DesignSystem.Spacing.xs) {
                                    // Top anchor (sentinel)
                                    Color.clear
                                        .frame(height: 1)
                                        .id("top")
                                        .onAppear { isAtTop = true }
                                        .onDisappear { isAtTop = false }

                                    ForEach(viewModel.logEntries) { log in
                                        LogEntryRowView(
                                            log: log,
                                            isSelected: selectedLogID == log.id
                                        ) {
                                            selectedLogID = log.id
                                        }
                                    }

                                    // Bottom anchor (sentinel)
                                    Color.clear
                                        .frame(height: 1)
                                        .id("bottom")
                                        .onAppear { isAtBottom = true }
                                        .onDisappear { isAtBottom = false }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                            }

                            // Floating buttons (top: Back to Latest, bottom: Load Older)
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            proxy.scrollTo("top", anchor: .top)
                                        }
                                    }) {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            Image(systemName: "arrow.up.to.line")
                                                .font(.system(size: 12))
                                            Text("Back to Latest")
                                                .font(DesignSystem.Typography.caption)
                                        }
                                    }
                                    .buttonStyle(LinearButtonStyle(variant: .secondary))
                                    .opacity(isAtTop ? 0 : 1)
                                    .allowsHitTesting(!isAtTop)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.top, DesignSystem.Spacing.md)

                                Spacer()

                                HStack {
                                    Spacer()
                                    Button(action: { viewModel.loadOlder() }) {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            if viewModel.isPaginating {
                                                ProgressView()
                                                    .scaleEffect(0.6)
                                            } else {
                                                Image(systemName: "chevron.down")
                                                    .font(.system(size: 12))
                                            }
                                            Text("Load Older")
                                                .font(DesignSystem.Typography.caption)
                                        }
                                    }
                                    .buttonStyle(LinearButtonStyle(variant: (isAtBottom && !(isAtTop && isAtBottom)) ? .primary : .secondary))
                                    .disabled(viewModel.isLoadingLogs || viewModel.isPaginating)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.bottom, DesignSystem.Spacing.md)

                                
                            }
                        }
                    }
                }
            }
        }
                .navigationSplitViewColumnWidth(min: 450, ideal: 500)
    }
    
    private var selectedLog: LogEntry? {
        guard let selectedLogID = selectedLogID else { return nil }
        return viewModel.logEntries.first { $0.id == selectedLogID }
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
                viewModel.errorMessage = nil
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

// (no preference keys required for sentinel-based detection)

/*
#Preview {
    ContentView()
}
*/
