
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

private struct JsonPayloadView: View {
    let data: Data?

    var body: some View {
        ScrollView {
            Text(prettyPrintedJsonString())
                .font(DesignSystem.Typography.mono)
                .padding(DesignSystem.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
        .frame(minHeight: 200)
    }

    private func prettyPrintedJsonString() -> String {
        guard let data = data else { return "No data" }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return String(data: data, encoding: .utf8) ?? "Failed to decode as UTF-8 string"
        }
        return String(data: prettyData, encoding: .utf8) ?? ""
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


