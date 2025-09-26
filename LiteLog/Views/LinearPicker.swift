
import SwiftUI

struct LinearPicker<T: Hashable & CustomStringConvertible>: View {
    @Binding var selection: T
    let options: [T]

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(options, id: \.self) { option in
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                    }
                }) {
                    Text(option.description)
                        .font(DesignSystem.Typography.bodyMedium)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(
                            ZStack {
                                if selection == option {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                        .fill(DesignSystem.Colors.surface)
                                        .shadow(radius: 2, y: 1)
                                }
                            }
                        )
                        .foregroundColor(selection == option ? DesignSystem.Colors.textPrimary : DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.background.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}
