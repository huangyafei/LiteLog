
import SwiftUI

struct FormattedView: View {
    let requestPayload: Data?
    let responsePayload: Data?

    // MARK: - Computed Properties for Decoded Data

    private var decodedRequest: ChatRequestPayload? {
        guard let data = requestPayload else { return nil }
        return try? JSONDecoder().decode(ChatRequestPayload.self, from: data)
    }

    private var decodedResponse: ChatResponsePayload? {
        guard let data = responsePayload else { return nil }
        return try? JSONDecoder().decode(ChatResponsePayload.self, from: data)
    }

    private var toolDefinitions: [ToolDefinition] {
        decodedRequest?.tools ?? []
    }

    private var messages: [ChatMessage] {
        var allMessages = decodedRequest?.messages ?? []
        if let responseMessage = decodedResponse?.choices.first?.message {
            allMessages.append(responseMessage)
        }
        return allMessages
    }

    private var calledToolNames: Set<String> {
        guard let responseMessage = decodedResponse?.choices.first?.message else { return [] }
        
        var names = Set<String>()
        if responseMessage.role == "assistant", let toolCalls = responseMessage.toolCalls {
            for call in toolCalls {
                names.insert(call.function.name)
            }
        }
        return names
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                // LLOG-12: Add Tools Definition Section
                if !toolDefinitions.isEmpty {
                    ToolsSectionView(
                        toolDefinitions: toolDefinitions,
                        calledToolNames: calledToolNames
                    )
                }
                
                // Existing Messages Section
                if !messages.isEmpty {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Messages")
                            .font(DesignSystem.Typography.titleSmall)
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        ForEach(messages) { message in
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text(message.role.capitalized)
                                    .font(DesignSystem.Typography.titleSmall)
                                    .foregroundColor(DesignSystem.Colors.textSecondary)
                                    .padding(.horizontal, DesignSystem.Spacing.md)

                                MessageCard(message: message)
                            }
                        }
                    }
                } else if toolDefinitions.isEmpty {
                    Text("No messages or tool definitions found in payload.")
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                        .padding()
                }
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .frame(minHeight: 400)
    }
}

struct MessageCard: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Spacer()
                Button(action: {
                    copyToClipboard(message)
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if let content = message.content, !content.isEmpty {
                Text(content)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .textSelection(.enabled)
            } else if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    ForEach(toolCalls) { toolCall in
                        VStack(alignment: .leading) {
                            Text("Tool Call: \(toolCall.function.name)")
                                .font(DesignSystem.Typography.bodyMedium)
                                .foregroundColor(DesignSystem.Colors.textPrimary)
                            Text("Arguments: \(toolCall.function.arguments)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(DesignSystem.Colors.textSecondary)
                                .textSelection(.enabled)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                }
            } else {
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
    
    private func copyToClipboard(_ message: ChatMessage) {
        let textToCopy: String
        if let content = message.content, !content.isEmpty {
            textToCopy = content
        } else if let toolCalls = message.toolCalls, !toolCalls.isEmpty {
            textToCopy = toolCalls.map { "Tool: \($0.function.name), Args: \($0.function.arguments)" }.joined(separator: "\n")
        } else {
            textToCopy = ""
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(textToCopy, forType: .string)
    }
}
