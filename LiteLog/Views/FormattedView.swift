import SwiftUI

struct FormattedView: View {
    let requestPayload: Data?
    let responsePayload: Data?
    let provider: String?
    let model: String?

    // MARK: - Computed Properties for Parsed Data

    private var parser: PayloadParser {
        PayloadParserFactory.create(provider: provider, model: model)
    }

    private var parsedRequest: UnifiedPayload? {
        guard let data = requestPayload else { return nil }
        return parser.parseRequest(data: data)
    }

    private var parsedResponse: UnifiedPayload? {
        guard let data = responsePayload else { return nil }
        return parser.parseResponse(data: data)
    }

    private var toolDefinitions: [ToolDefinition] {
        parsedRequest?.tools ?? []
    }

    private var messages: [ChatMessage] {
        var allMessages = parsedRequest?.messages ?? []
        if let responseMessages = parsedResponse?.messages {
            allMessages.append(contentsOf: responseMessages)
        }
        return allMessages
    }

    private var calledToolNames: Set<String> {
        // Iterate over all assistant messages to find tool calls
        // Usually the last message in response is the assistant's reply/tool call
        guard let responseMessages = parsedResponse?.messages else { return [] }
        
        var names = Set<String>()
        for message in responseMessages {
            if message.role == "assistant" || message.role == "model", let toolCalls = message.toolCalls {
                for call in toolCalls {
                    names.insert(call.function.name)
                }
            }
        }
        return names
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // LLOG-12: Add Tools Definition Section
                if !toolDefinitions.isEmpty {
                    ToolsSectionView(
                        toolDefinitions: toolDefinitions,
                        calledToolNames: calledToolNames
                    )
                    
                    if !messages.isEmpty {
                        Divider()
                            .padding(.vertical, DesignSystem.Spacing.lg)
                    }
                }
                
                // Existing Messages Section
                if !messages.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        HStack {
                            SectionHeader(title: "Messages")
                            Spacer()
                        }

                        ForEach(messages) { message in
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                // Title row with copy button
                                HStack {
                                    Text(message.role.capitalized)
                                        .font(DesignSystem.Typography.titleSmall)
                                        .foregroundColor(DesignSystem.Colors.textSecondary)
                                    
                                    Spacer()
                                    
                                    Button(action: { copyToClipboard(message) }) {
                                        Image(systemName: "doc.on.doc")
                                            .font(.system(size: 12))
                                            .foregroundColor(DesignSystem.Colors.textSecondary)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)

                                MessageCard(message: message)
                            }
                            .padding(.bottom, DesignSystem.Spacing.lg)
                        }
                    }
                } else if toolDefinitions.isEmpty {
                    Text("No messages or tool definitions found in payload.")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                }
            }
        }
        .frame(minHeight: 400)
    }
    
    private func copyToClipboard(_ message: ChatMessage) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message.copyableString, forType: .string)
    }
}

struct MessageCard: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // Display Content if available
            if let content = message.content, !content.isEmpty {
                Text(content)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
            }
            
            // Display Tool Calls if available
            if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                if message.content != nil && !message.content!.isEmpty {
                    Divider()
                        .padding(.vertical, DesignSystem.Spacing.xs)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                    ForEach(toolCalls) { toolCall in
                        ToolCallView(toolCall: toolCall)
                    }
                }
            }
            
            // Fallback for empty message
            if (message.content == nil || message.content!.isEmpty) && (message.toolCalls == nil || message.toolCalls!.isEmpty) {
                Text("Empty message")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .cornerRadius(DesignSystem.CornerRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - ToolCallView

struct ToolCallView: View {
    let toolCall: ToolCall

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            Image(systemName: "wrench.and.screwdriver.fill")
                .font(.system(size: 14))
                .foregroundColor(DesignSystem.Colors.textTertiary)
                .padding(.top, 2) // Fine-tune alignment

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(toolCall.function.name)
                    .font(DesignSystem.Typography.bodyMedium)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Text(toolCall.function.arguments)
                    .font(DesignSystem.Typography.mono)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .textSelection(.enabled)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.backgroundSecondary)
        .cornerRadius(DesignSystem.CornerRadius.sm)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                .stroke(DesignSystem.Colors.border, lineWidth: 1)
        )
    }
}