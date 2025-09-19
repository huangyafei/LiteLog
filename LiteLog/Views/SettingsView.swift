

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Settings")
                            .font(DesignSystem.Typography.titleLarge)
                            .foregroundColor(DesignSystem.Colors.textPrimary)
                        
                        Text("Configure your LiteLLM connection")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                .padding(.vertical, DesignSystem.Spacing.xl)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Form Content
                VStack(spacing: DesignSystem.Spacing.xl) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Base URL")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            TextField("https://your-litellm-instance.com", text: $viewModel.baseURL)
                                .textFieldStyle(LinearTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Admin API Key")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            
                            SecureField("Enter your admin API key", text: $viewModel.adminApiKey)
                                .textFieldStyle(LinearTextFieldStyle())
                            
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Image(systemName: "lock.shield")
                                        .font(.system(size: 12))
                                        .foregroundColor(DesignSystem.Colors.textTertiary)
                                    
                                    Text("Your API Key is stored only on your local device and is not sent to the application developer.")
                                        .font(DesignSystem.Typography.caption)
                                        .foregroundColor(DesignSystem.Colors.textTertiary)
                                }
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, DesignSystem.Spacing.xs)
                        }

                        // Log options
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                            Text("Log Options")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)

                            HStack(spacing: DesignSystem.Spacing.md) {
                                Text("Lookback")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 120, alignment: .leading)
                                Stepper(value: $viewModel.lookbackHours, in: 1...168, step: 1) {
                                    Text("\(viewModel.lookbackHours) h")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                            }

                            HStack(spacing: DesignSystem.Spacing.md) {
                                Text("Page Size")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .frame(width: 120, alignment: .leading)
                                Stepper(value: $viewModel.pageSize, in: 10...500, step: 10) {
                                    Text("\(viewModel.pageSize)")
                                        .font(DesignSystem.Typography.body)
                                        .foregroundColor(DesignSystem.Colors.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.xxl)
                    .padding(.top, DesignSystem.Spacing.xl)
                }
                
                Spacer()
                
                // Footer
                Divider()
                    .background(DesignSystem.Colors.border)
                
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(LinearButtonStyle(variant: .secondary))
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("Save Settings") {
                        viewModel.saveSettings()
                    }
                    .buttonStyle(LinearButtonStyle(variant: .primary))
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.horizontal, DesignSystem.Spacing.xxl)
                .padding(.vertical, DesignSystem.Spacing.lg)
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .onAppear {
            viewModel.loadSettings()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("LiteLog"),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("OK")) {
                    if viewModel.alertMessage == "Settings saved successfully!" {
                        dismiss()
                    }
                }
            )
        }
    }
}

/*
#Preview {
    SettingsView()
}
*/
