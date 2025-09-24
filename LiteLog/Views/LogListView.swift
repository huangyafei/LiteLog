import SwiftUI

struct LogListView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @ObservedObject var viewModel: ContentViewModel

    @State private var isAtTop: Bool = true
    @State private var isAtBottom: Bool = false
    @FocusState private var isLogListFocused: Bool

    var body: some View {
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
                    
                    if !appEnvironment.currentLogEntries.isEmpty {
                        Text("\(appEnvironment.currentLogEntries.count) entries")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(DesignSystem.Colors.textTertiary)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.md)
                
                Divider()
                    .background(DesignSystem.Colors.border)
                
                // Content
                if appEnvironment.isLoadingLogs {
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
                } else if let selectedKeyID = appEnvironment.selectedKeyID, !selectedKeyID.isEmpty, appEnvironment.currentLogEntries.isEmpty {
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

                                    ForEach(appEnvironment.currentLogEntries) { log in
                                        LogEntryRowView(
                                            log: log,
                                            isSelected: appEnvironment.selectedLogEntryId == log.id,
                                            isFocused: viewModel.focusedLogEntryId == log.id
                                        ) {
                                            appEnvironment.selectedLogEntryId = log.id
                                            viewModel.clearFocus()
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
                                    Button(action: { appEnvironment.loadOlder() }) {
                                        HStack(spacing: DesignSystem.Spacing.xs) {
                                            if appEnvironment.isPaginating {
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
                                    .disabled(appEnvironment.isLoadingLogs || appEnvironment.isPaginating)
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.bottom, DesignSystem.Spacing.md)
                            }
                        }
                    }
                }
            }
        }
        .focusable()
        .focused($isLogListFocused)
        .focusEffectDisabled()
        .onAppear { isLogListFocused = true }
        .onKeyPress(action: handleKeyPress)
        .navigationSplitViewColumnWidth(min: 450, ideal: 500)
    }
    
    private func handleKeyPress(press: KeyPress) -> KeyPress.Result {
        switch press.key {
        case .upArrow:
            viewModel.moveFocus(down: false)
            return .handled
        case .downArrow:
            viewModel.moveFocus(down: true)
            return .handled
        case .return:
            viewModel.selectFocusedItem()
            return .handled
        default:
            return .ignored
        }
    }
}
