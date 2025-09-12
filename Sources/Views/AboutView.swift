
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Image(systemName: "paperplane.fill") // Placeholder icon
                .font(.system(size: 64))
                .foregroundColor(DesignSystem.Colors.primary)
            
            VStack(spacing: DesignSystem.Spacing.xs) {
                Text("LiteLog")
                    .font(DesignSystem.Typography.titleLarge)
                
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                    Text("Version \(version)")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
            }
            
            Text("A native macOS application for viewing LiteLLM logs.")
                .font(DesignSystem.Typography.body)
                .multilineTextAlignment(.center)
            
            if let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String {
                Text(copyright)
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
            }
        }
        .padding(DesignSystem.Spacing.xxxl)
        .frame(minWidth: 300)
        .background(DesignSystem.Colors.background)
    }
}
