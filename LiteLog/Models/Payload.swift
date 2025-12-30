import Foundation

// MARK: - Unified Models

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
    
    // Manual initializer for Parser usage
    init(role: String, content: String? = nil, toolCalls: [ToolCall]? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.role = try container.decode(String.self, forKey: .role)
        self.content = try container.decodeIfPresent(String.self, forKey: .content)
        self.toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
    }
    
    var copyableString: String {
        if let content = content, !content.isEmpty {
            return content
        } else if let toolCalls = toolCalls, !toolCalls.isEmpty {
            return toolCalls.map { "Tool: \($0.function.name), Args: \($0.function.arguments)" }.joined(separator: "\n")
        } else {
            return ""
        }
    }
}

struct ToolCall: Codable, Hashable, Identifiable {
    var id: String
    let type: String
    let function: FunctionCall

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case function
    }
    
    // Manual initializer
    init(id: String = UUID().uuidString, type: String = "function", function: FunctionCall) {
        self.id = id
        self.type = type
        self.function = function
    }
}

struct FunctionCall: Codable, Hashable {
    let name: String
    let arguments: String // Arguments are typically a JSON string
}

// For LLOG-12: Tool Definition Card
struct ToolDefinition: Codable, Hashable, Identifiable {
    var id = UUID()
    let type: String
    let function: FunctionDefinition
    
    enum CodingKeys: String, CodingKey {
        case type, function
    }
    
    // Manual initializer
    init(type: String = "function", function: FunctionDefinition) {
        self.type = type
        self.function = function
    }
}

struct FunctionDefinition: Codable, Hashable {
    let name: String
    let description: String?
    let parameters: ParametersDefinition?
}

struct ParametersDefinition: Codable, Hashable {
    let type: String?
    let properties: [String: PropertyDefinition]?
    let required: [String]?
}

struct PropertyDefinition: Codable, Hashable {
    let type: String
    let description: String?
    let `enum`: [String]?
}


struct ChatRequestPayload: Codable {
    let messages: [ChatMessage]
    let tools: [ToolDefinition]?

    enum CodingKeys: String, CodingKey {
        case messages, tools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        messages = try container.decode([ChatMessage].self, forKey: .messages)
        tools = try container.decodeIfPresent([ToolDefinition].self, forKey: .tools)
    }
    
    // Add a default initializer to keep memberwise initializer for other parts of the app if needed
    init(messages: [ChatMessage], tools: [ToolDefinition]?) {
        self.messages = messages
        self.tools = tools
    }
}

struct ChatResponsePayload: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: ChatMessage
}

// MARK: - Helper Types

// Helper for decoding/encoding arbitrary JSON values
struct AnyCodable: Codable, Hashable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self.value = ()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case is Void, is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // This is a simplified equality check. A full implementation is complex.
        return false // Approximation
    }

    func hash(into hasher: inout Hasher) {
        // This is a simplified hash. A full implementation is complex.
    }
}
