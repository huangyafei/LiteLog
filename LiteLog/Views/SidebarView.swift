import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @Environment(\.openWindow) var openWindow

    var body: some View {
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
                    
                    Button(action: { appEnvironment.refreshKeysAndLogs() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14))
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .help("Refresh API Key list")
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Content
                if appEnvironment.isLoadingKeys {
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
                } else if appEnvironment.virtualKeys.isEmpty {
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
                            ForEach(appEnvironment.virtualKeys) { key in
                                KeyRowView(
                                    key: key, 
                                    isSelected: appEnvironment.selectedKeyID == key.id
                                ) {
                                    appEnvironment.selectedKeyID = key.id
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
}
