
import SwiftUI

struct LogDetailView: View {
    let log: LogEntry?

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea(.all)
            
            if let log = self.log {
                ScrollView {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                        header(log: log)
                        details(log: log)
                        payloads(log: log)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                    .padding(.vertical, DesignSystem.Spacing.xl)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(DesignSystem.Colors.textTertiary)
                    
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Select a log to see details")
                            .font(DesignSystem.Typography.title)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                        
                        Text("Choose a log entry from the list to view its complete information")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func header(log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.lg) {
                StatusBadge(
                    status: log.status,
                    isSuccess: log.status == "success"
                )
                
                Spacer()
                
                Text("\(String(format: "%.8f", log.spend)) USD")
                    .font(DesignSystem.Typography.titleSmall)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.surface)
                    .cornerRadius(DesignSystem.CornerRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.border, lineWidth: 1)
                    )
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(log.model)
                    .font(DesignSystem.Typography.titleLarge)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text("Request ID: \(log.requestId)")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                    .textSelection(.enabled)
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .linearCard()
    }
    
    @ViewBuilder
    private func details(log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            Text("Details")
                .font(DesignSystem.Typography.title)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                DetailRow(label: "Start Time", value: formattedDate(log.startTime))
                DetailRow(label: "End Time", value: formattedDate(log.endTime))
                DetailRow(label: "Duration", value: "\(duration(from: log.startTime, to: log.endTime))s")
                
                if let totalTokens = log.totalTokens {
                    DetailRow(label: "Total Tokens", value: "\(totalTokens)")
                }
                
                if let promptTokens = log.promptTokens {
                    DetailRow(label: "Prompt Tokens", value: "\(promptTokens)")
                }
                
                if let completionTokens = log.completionTokens {
                    DetailRow(label: "Completion Tokens", value: "\(completionTokens)")
                }
                
                if let user = log.user, !user.isEmpty {
                    DetailRow(label: "User", value: user)
                }
                
                if let cacheHit = log.cacheHit {
                    DetailRow(label: "Cache Hit", value: cacheHit)
                }
                
                if let provider = log.customLlmProvider, !provider.isEmpty {
                    DetailRow(label: "Provider", value: provider)
                }

                if let apiBase = log.apiBase, let url = URL(string: apiBase), let scheme = url.scheme, let host = url.host {
                    let truncatedApiBase = "\(scheme)://\(host)"
                    DetailRow(label: "API Base", value: truncatedApiBase)
                }
            }
        }
        .padding(DesignSystem.Spacing.xl)
        .linearCard()
    }
    
    @ViewBuilder
    private func payloads(log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack {
                    Text("Request Payload")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        copyPayloadToClipboard(log.requestPayload)
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("Copy")
                                .font(DesignSystem.Typography.caption)
                        }
                    }
                    .buttonStyle(LinearButtonStyle(variant: .ghost))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                JsonPayloadView(data: log.requestPayload)
            }
            .padding(DesignSystem.Spacing.xl)
            .linearCard()
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack {
                    Text("Response Payload")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        copyPayloadToClipboard(log.responsePayload)
                    }) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 12))
                            Text("Copy")
                                .font(DesignSystem.Typography.caption)
                        }
                    }
                    .buttonStyle(LinearButtonStyle(variant: .ghost))
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                JsonPayloadView(data: log.responsePayload)
            }
            .padding(DesignSystem.Spacing.xl)
            .linearCard()
        }
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .abbreviated, time: .complete)
        }
        return "Invalid Date"
    }
    
    private func duration(from start: String, to end: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let startDate = formatter.date(from: start), let endDate = formatter.date(from: end) {
            let duration = endDate.timeIntervalSince(startDate)
            return String(format: "%.3f", duration)
        }
        return "--"
    }
    
    private func copyPayloadToClipboard(_ data: Data?) {
        guard let data = data else { return }
        
        let prettyJsonString: String
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) {
            prettyJsonString = String(data: prettyData, encoding: .utf8) ?? ""
        } else {
            prettyJsonString = String(data: data, encoding: .utf8) ?? ""
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(prettyJsonString, forType: .string)
    }
}

// MARK: - JSON Cache Manager
private class JsonCacheManager {
    static let shared = JsonCacheManager()
    private var cache: [String: String] = [:]
    private let queue = DispatchQueue(label: "json-cache", qos: .utility, attributes: .concurrent)

    private init() {}

    func getCachedJson(for data: Data) -> String? {
        let key = data.hashValue.description
        return queue.sync {
            return cache[key]
        }
    }

    func setCachedJson(_ json: String, for data: Data) {
        let key = data.hashValue.description
        queue.async(flags: .barrier) {
            self.cache[key] = json

            // 限制缓存大小，超过 50 个条目时清理
            if self.cache.count > 50 {
                let keysToRemove = Array(self.cache.keys.prefix(10))
                for keyToRemove in keysToRemove {
                    self.cache.removeValue(forKey: keyToRemove)
                }
            }
        }
    }
}

private struct JsonPayloadView: View {
    let data: Data?

    @State private var formattedJson: String = ""
    @State private var isLoading: Bool = true
    @State private var isTruncated: Bool = false
    @State private var showFullContent: Bool = false
    @State private var loadingTask: Task<Void, Never>?

    private let maxDisplayLength = 50000 // 约 50KB 的字符限制
    private let maxDataSize = 1024 * 1024 // 1MB 限制

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                if isLoading {
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: DesignSystem.Colors.primary))
                            .scaleEffect(0.8)
                        Text("Formatting JSON...")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.xl)
                } else {
                    if isTruncated && !showFullContent {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(DesignSystem.Colors.warning)
                                Text("Large payload detected. Showing first \(formatNumber(maxDisplayLength)) characters.")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                Spacer()
                                Button("Show Full") {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showFullContent = true
                                    }
                                }
                                .buttonStyle(LinearButtonStyle(variant: .ghost))
                                .font(DesignSystem.Typography.caption)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.warning.opacity(0.1))
                            .cornerRadius(DesignSystem.CornerRadius.sm)
                        }
                    }

                    Text(displayText)
                        .font(DesignSystem.Typography.mono)
                        .padding(DesignSystem.Spacing.lg)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .textSelection(.enabled)
                }
            }
        }
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .frame(minHeight: 200)
        .onAppear {
            loadJsonAsync()
        }
        .onChange(of: data) { _ in
            // 取消之前的任务
            loadingTask?.cancel()

            // 重置状态并重新加载
            isLoading = true
            formattedJson = ""
            isTruncated = false
            showFullContent = false
            loadJsonAsync()
        }
        .onDisappear {
            // 视图消失时取消加载任务
            loadingTask?.cancel()
        }
    }

    private var displayText: String {
        if showFullContent || !isTruncated {
            return formattedJson
        } else {
            return String(formattedJson.prefix(maxDisplayLength)) + "\n\n... (truncated)"
        }
    }

    private func loadJsonAsync() {
        guard let data = data else {
            DispatchQueue.main.async {
                self.formattedJson = "No data"
                self.isLoading = false
            }
            return
        }

        // 检查数据大小
        if data.count > maxDataSize {
            DispatchQueue.main.async {
                self.formattedJson = "Payload too large (\(self.formatBytes(data.count))). Please use the copy function to view the full content."
                self.isLoading = false
            }
            return
        }

        // 首先检查缓存
        if let cachedJson = JsonCacheManager.shared.getCachedJson(for: data) {
            DispatchQueue.main.async {
                self.formattedJson = cachedJson
                self.isTruncated = cachedJson.count > self.maxDisplayLength
                self.isLoading = false
            }
            return
        }

        // 创建异步任务
        loadingTask = Task { @MainActor in
            do {
                let result = try await formatJsonDataAsync(data)

                // 检查任务是否被取消
                if !Task.isCancelled {
                    self.formattedJson = result
                    self.isTruncated = result.count > self.maxDisplayLength
                    self.isLoading = false

                    // 缓存结果
                    JsonCacheManager.shared.setCachedJson(result, for: data)
                }
            } catch {
                if !Task.isCancelled {
                    self.formattedJson = "Failed to format JSON: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func formatJsonDataAsync(_ data: Data) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let result = formatJsonData(data)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func formatJsonData(_ data: Data) -> String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return String(data: data, encoding: .utf8) ?? "Failed to decode as UTF-8 string"
        }
        return String(data: prettyData, encoding: .utf8) ?? ""
    }

    private func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.md) {
            Text(label)
                .font(DesignSystem.Typography.bodyMedium)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .frame(width: 140, alignment: .leading)
            
            Text(value)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
}


