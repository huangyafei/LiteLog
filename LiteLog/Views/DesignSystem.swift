import SwiftUI

// MARK: - Design System inspired by Linear

struct DesignSystem {
    
    // MARK: - Colors
    struct Colors {
        // Background Colors
        static let background = Color(red: 0.02, green: 0.02, blue: 0.04) // Very dark blue-black
        static let backgroundSecondary = Color(red: 0.04, green: 0.05, blue: 0.08) // Slightly lighter
        static let backgroundTertiary = Color(red: 0.06, green: 0.07, blue: 0.11)
        static let surface = Color(red: 0.08, green: 0.09, blue: 0.13)
        static let surfaceHover = Color(red: 0.10, green: 0.11, blue: 0.15)
        
        // Border Colors
        static let border = Color(red: 0.12, green: 0.13, blue: 0.17)
        static let borderHover = Color(red: 0.16, green: 0.17, blue: 0.21)
        static let borderFocus = Color(red: 0.24, green: 0.51, blue: 1.0) // Linear blue
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(red: 0.64, green: 0.66, blue: 0.73)
        static let textTertiary = Color(red: 0.45, green: 0.47, blue: 0.54)
        static let textMuted = Color(red: 0.35, green: 0.37, blue: 0.44)
        
        // Accent Colors
        static let primary = Color(red: 0.24, green: 0.51, blue: 1.0) // Linear blue
        static let primaryHover = Color(red: 0.20, green: 0.45, blue: 0.90)
        static let success = Color(red: 0.16, green: 0.8, blue: 0.4)
        static let error = Color(red: 1.0, green: 0.32, blue: 0.32)
        static let warning = Color(red: 1.0, green: 0.8, blue: 0.2)
        
        // Status Colors
        static let successBackground = Color(red: 0.16, green: 0.8, blue: 0.4).opacity(0.1)
        static let errorBackground = Color(red: 1.0, green: 0.32, blue: 0.32).opacity(0.1)
    }
    
    // MARK: - Typography
    struct Typography {
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let title = Font.system(size: 18, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 16, weight: .medium, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .medium, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let xxxl: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 4
        static let md: CGFloat = 6
        static let lg: CGFloat = 8
        static let xl: CGFloat = 12
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let small = Color.black.opacity(0.1)
        static let medium = Color.black.opacity(0.15)
        static let large = Color.black.opacity(0.2)
    }
}

// MARK: - Custom View Modifiers

struct LinearCardStyle: ViewModifier {
    let isInteractive: Bool
    @State private var isHovered = false
    
    init(isInteractive: Bool = false) {
        self.isInteractive = isInteractive
    }
    
    func body(content: Content) -> some View {
        content
            .background(isHovered && isInteractive ? DesignSystem.Colors.surfaceHover : DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isHovered && isInteractive ? DesignSystem.Colors.borderHover : DesignSystem.Colors.border, lineWidth: 1)
            )
            .onHover { hovering in
                if isInteractive {
                    isHovered = hovering
                }
            }
    }
}

struct LinearButtonStyle: ButtonStyle {
    let variant: Variant
    
    enum Variant {
        case primary
        case secondary
        case ghost
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.bodyMedium)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(backgroundColor(configuration: configuration))
            .foregroundColor(foregroundColor(configuration: configuration))
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(borderColor(configuration: configuration), lineWidth: variant == .secondary ? 1 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        switch variant {
        case .primary:
            return configuration.isPressed ? DesignSystem.Colors.primaryHover : DesignSystem.Colors.primary
        case .secondary:
            return configuration.isPressed ? DesignSystem.Colors.surfaceHover : DesignSystem.Colors.surface
        case .ghost:
            return configuration.isPressed ? DesignSystem.Colors.surface : Color.clear
        }
    }
    
    private func foregroundColor(configuration: Configuration) -> Color {
        switch variant {
        case .primary:
            return .white
        case .secondary, .ghost:
            return DesignSystem.Colors.textPrimary
        }
    }
    
    private func borderColor(configuration: Configuration) -> Color {
        switch variant {
        case .primary, .ghost:
            return Color.clear
        case .secondary:
            return configuration.isPressed ? DesignSystem.Colors.borderHover : DesignSystem.Colors.border
        }
    }
}

// MARK: - View Extensions

extension View {
    func linearCard(isInteractive: Bool = false) -> some View {
        self.modifier(LinearCardStyle(isInteractive: isInteractive))
    }
}

// MARK: - Linear Text Field Style

struct LinearTextFieldStyle: TextFieldStyle {
    @State private var isFocused = false
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(DesignSystem.Typography.body)
            .foregroundColor(DesignSystem.Colors.textPrimary)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(isFocused ? DesignSystem.Colors.borderFocus : DesignSystem.Colors.border, lineWidth: 1)
            )
            .onTapGesture {
                isFocused = true
            }
            .onSubmit {
                isFocused = false
            }
    }
}

// MARK: - Status Badge View

struct StatusBadge: View {
    let status: String
    let isSuccess: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Circle()
                .fill(isSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                .frame(width: 6, height: 6)
            
            Text(status.capitalized)
                .font(DesignSystem.Typography.captionMedium)
                .foregroundColor(isSuccess ? DesignSystem.Colors.success : DesignSystem.Colors.error)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(isSuccess ? DesignSystem.Colors.successBackground : DesignSystem.Colors.errorBackground)
        .cornerRadius(DesignSystem.CornerRadius.sm)
    }
}

extension Color {
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 5/255, green: 5/255, blue: 10/255), // rgb(5, 5, 10)
                Color(red: 20/255, green: 23/255, blue: 33/255) // rgb(20, 23, 33)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DesignSystem.Typography.title)
            .foregroundColor(DesignSystem.Colors.textPrimary)
    }
}