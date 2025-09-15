import SwiftUI

struct KeyRowView: View {
    let key: VirtualKey
    let isSelected: Bool
    let onSelect: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(key.keyAlias ?? key.keyName)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                        
                        Text("\(String(format: "%.4f", key.spend)) USD")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer(minLength: 0)
                }
            }
            
            Spacer(minLength: 0)
            
            if isSelected {
                Circle()
                    .fill(DesignSystem.Colors.primary)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Group {
                if isSelected {
                    DesignSystem.Colors.primary.opacity(0.08)
                } else if isHovered {
                    DesignSystem.Colors.surfaceHover
                } else {
                    Color.clear
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(
                    isSelected ? DesignSystem.Colors.primary.opacity(0.3) : Color.clear,
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
}