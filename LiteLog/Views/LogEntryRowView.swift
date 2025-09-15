
import SwiftUI

struct LogEntryRowView: View {
    let log: LogEntry
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .center, spacing: DesignSystem.Spacing.md) {
                StatusBadge(
                    status: log.status,
                    isSuccess: log.status == "success"
                )
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(log.model)
                        .font(DesignSystem.Typography.bodyMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            Text(formattedDate(log.startTime))
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                        
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "timer")
                                .font(.system(size: 10))
                                .foregroundColor(DesignSystem.Colors.textTertiary)
                            
                            Text("\(duration(from: log.startTime, to: log.endTime))s")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                        }
                    }
                }
                
                Spacer(minLength: 0)
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    Text("\(String(format: "%.6f", log.spend)) USD")
                        .font(DesignSystem.Typography.captionMedium)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    if let totalTokens = log.totalTokens {
                        Text("\(totalTokens) tokens")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    DesignSystem.Colors.primary.opacity(0.08)
                } else if isHovered {
                    DesignSystem.Colors.surfaceHover
                } else {
                    DesignSystem.Colors.surface
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    isSelected ? DesignSystem.Colors.primary.opacity(0.3) : DesignSystem.Colors.border,
                    lineWidth: 1
                )
        )
        .cornerRadius(DesignSystem.CornerRadius.md)
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date.formatted(date: .numeric, time: .standard)
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
}
