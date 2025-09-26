import Foundation

struct ChatMessage: Codable, Hashable, Identifiable {
    var id = UUID()
    let role: String
    let content: String?
    let toolCalls: [ToolCall]?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCalls = "tool_calls"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
        
        // If content is nil and toolCalls is also nil, it's an invalid message, but we'll allow it for now.
        // If content is nil, but toolCalls exist, we should ensure content is not just an empty string.
        // For now, we'll keep content as optional String.
    }
}

struct ToolCall: Codable, Hashable, Identifiable {
    var id: String // This is the 'id' from the JSON, e.g., "call_vaIva6JAahiDBmj3Ut6xfFq0"
    let type: String
    let function: FunctionCall

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case function
    }
}

struct FunctionCall: Codable, Hashable {
    let name: String
    let arguments: String // Arguments are typically a JSON string
}

struct ChatRequestPayload: Codable {
    let messages: [ChatMessage]
}

struct ChatResponsePayload: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}