import Foundation

// MARK: - Unified Payload

struct UnifiedPayload {
    let messages: [ChatMessage]
    let tools: [ToolDefinition]
}

// MARK: - Parser Protocol

protocol PayloadParser {
    func parseRequest(data: Data) -> UnifiedPayload?
    func parseResponse(data: Data) -> UnifiedPayload?
}

// MARK: - Factory

struct PayloadParserFactory {
    static func create(provider: String?, model: String?) -> PayloadParser {
        // 1. Try to detect by Provider
        if let provider = provider?.lowercased() {
            if provider.contains("google") || provider.contains("vertex") || provider.contains("gemini") {
                return GeminiPayloadParser()
            } else if provider.contains("anthropic") || provider.contains("claude") {
                return ClaudePayloadParser()
            }
        }
        
        // 2. Fallback: Detect by Model Name
        if let model = model?.lowercased() {
            if model.contains("gemini") {
                return GeminiPayloadParser()
            } else if model.contains("claude") {
                return ClaudePayloadParser()
            }
        }
        
        // 3. Default to OpenAI (and its variants)
        return OpenAIPayloadParser()
    }
}

// MARK: - OpenAI Parser (Enhanced for Variants)

class OpenAIPayloadParser: PayloadParser {
    
    // 1. Standard Request
    private struct StandardRequest: Codable {
        let messages: [ChatMessage]?
        let tools: [ToolDefinition]?
    }
    
    // 2. Variant Request
    private struct VariantRequest: Codable {
        let input: [VariantInputMessage]?
        let tools: [FlatToolDefinition]?
    }
    
    private struct VariantInputMessage: Codable {
        let role: String?
        let content: String?
        
        // Variant fields
        let type: String?
        let name: String?
        let arguments: String?
        let call_id: String?
        let output: String?
        
        func toChatMessage() -> ChatMessage {
            if let r = role {
                return ChatMessage(role: r, content: content)
            }
            
            // Infer role for variants
            if type == "function_call" {
                // Assistant calling a tool
                let toolCall = ToolCall(
                    id: call_id ?? UUID().uuidString,
                    function: FunctionCall(name: name ?? "unknown", arguments: arguments ?? "{}")
                )
                return ChatMessage(role: "assistant", toolCalls: [toolCall])
            }
            
            if type == "function_call_output" {
                // Tool output (role: tool)
                let cid = call_id ?? "unknown"
                let cstr = output ?? ""
                return ChatMessage(role: "tool", content: "Tool Output (ID: \(cid)): \(cstr)")
            }
            
            return ChatMessage(role: "unknown", content: "")
        }
    }
    
    private struct FlatToolDefinition: Codable {
        let type: String?
        let name: String?
        let description: String?
        let parameters: ParametersDefinition?
        
        // Handle standard nested "function" key too
        let function: FunctionDefinition?
        
        func toUnified() -> ToolDefinition {
            if let f = function {
                return ToolDefinition(type: type ?? "function", function: f)
            }
            return ToolDefinition(
                type: type ?? "function",
                function: FunctionDefinition(
                    name: name ?? "unknown",
                    description: description,
                    parameters: parameters
                )
            )
        }
    }
    
    // 3. Variant Response
    private struct VariantResponse: Codable {
        let output: [VariantOutput]?
    }
    
    private struct VariantOutput: Codable {
        let type: String?
        let role: String?
        let name: String?
        let arguments: String?
        let id: String?
        
        // Content can be String or Array
        let content: VariantContentWrapper?
        
        // Fallback for direct text field
        let text: String?
        
        // Fallback for arguments object
        let argumentsObj: AnyCodable?
        
        enum CodingKeys: String, CodingKey {
            case type, role, name, arguments, id, content, text
            // Skip argumentsObj in keys to avoid duplicate raw value
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            type = try container.decodeIfPresent(String.self, forKey: .type)
            role = try container.decodeIfPresent(String.self, forKey: .role)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            id = try container.decodeIfPresent(String.self, forKey: .id)
            text = try container.decodeIfPresent(String.self, forKey: .text)
            content = try container.decodeIfPresent(VariantContentWrapper.self, forKey: .content)
            
            if let argStr = try? container.decodeIfPresent(String.self, forKey: .arguments) {
                arguments = argStr
                argumentsObj = nil
            } else {
                arguments = nil
                argumentsObj = try container.decodeIfPresent(AnyCodable.self, forKey: .arguments)
            }
        }
        
        func getArgumentsString() -> String {
            if let args = arguments { return args }
            if let obj = argumentsObj {
                if let data = try? JSONEncoder().encode(obj), let str = String(data: data, encoding: .utf8) {
                    return str
                }
            }
            return "{}"
        }
        
        func getContentString() -> String? {
            if let wrapper = content {
                if let s = wrapper.stringValue { return s }
                if let arr = wrapper.arrayValue {
                    return arr.compactMap { $0.text }.joined(separator: "\n")
                }
            }
            return text
        }
    }
    
    private struct VariantContentWrapper: Codable {
        let stringValue: String?
        let arrayValue: [VariantInnerContent]?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                stringValue = str
                arrayValue = nil
            } else if let arr = try? container.decode([VariantInnerContent].self) {
                arrayValue = arr
                stringValue = nil
            } else {
                stringValue = nil
                arrayValue = nil
            }
        }
    }
    
    private struct VariantInnerContent: Codable {
        let type: String?
        let text: String?
    }

    func parseRequest(data: Data) -> UnifiedPayload? {
        // Try Standard First
        if let payload = try? JSONDecoder().decode(StandardRequest.self, from: data) {
            if let msgs = payload.messages {
                return UnifiedPayload(messages: msgs, tools: payload.tools ?? [])
            }
        }
        
        // Try Variant
        if let payload = try? JSONDecoder().decode(VariantRequest.self, from: data) {
            let tools = payload.tools?.map { $0.toUnified() } ?? []
            if let input = payload.input {
                let msgs = input.map { $0.toChatMessage() }
                return UnifiedPayload(messages: msgs, tools: tools)
            }
        }
        
        return nil
    }
    
    func parseResponse(data: Data) -> UnifiedPayload? {
        // Try Standard First
        if let payload = try? JSONDecoder().decode(ChatResponsePayload.self, from: data) {
            let messages = payload.choices.map { $0.message }
            return UnifiedPayload(messages: messages, tools: [])
        }
        
        // Try Variant
        if let payload = try? JSONDecoder().decode(VariantResponse.self, from: data),
           let outputs = payload.output {
            
            var messages: [ChatMessage] = []
            
            for out in outputs {
                if out.type == "message", let role = out.role {
                    let content = out.getContentString()
                    messages.append(ChatMessage(role: role, content: content))
                }
                else if (out.type == "function_call" || out.type == "tool_use"),
                   let name = out.name {
                    let id = out.id ?? UUID().uuidString
                    let args = out.getArgumentsString()
                    let toolCall = ToolCall(id: id, function: FunctionCall(name: name, arguments: args))
                    messages.append(ChatMessage(role: "assistant", toolCalls: [toolCall]))
                }
            }
            
            return UnifiedPayload(messages: messages, tools: [])
        }
        
        return nil
    }
}

// MARK: - Gemini Parser

class GeminiPayloadParser: PayloadParser {
    
    // Private structs for Gemini format
    private struct GeminiRequest: Codable {
        let contents: [GeminiContent]?
        let tools: [GeminiToolWrapper]?
    }
    
    private struct GeminiResponse: Codable {
        let candidates: [GeminiCandidate]?
    }
    
    private struct GeminiCandidate: Codable {
        let content: GeminiContent?
    }
    
    private struct GeminiContent: Codable {
        let role: String?
        let parts: [GeminiPart]?
    }
    
    private struct GeminiPart: Codable {
        let text: String?
        let functionCall: GeminiFunctionCall?
        let functionResponse: GeminiFunctionResponse?
    }
    
    private struct GeminiToolWrapper: Codable {
        let functionDeclarations: [FunctionDefinition]?
    }
    
    private struct GeminiFunctionCall: Codable {
        let name: String
        let args: [String: AnyCodable]? // Args come as JSON object
    }
    
    private struct GeminiFunctionResponse: Codable {
        let name: String
        let response: [String: AnyCodable]?
    }
    
    func parseRequest(data: Data) -> UnifiedPayload? {
        guard let request = try? JSONDecoder().decode(GeminiRequest.self, from: data) else { return nil }
        
        // Parse Messages
        let messages = (request.contents ?? []).map { content -> ChatMessage in
            return convertGeminiContent(content)
        }
        
        // Parse Tools
        var tools: [ToolDefinition] = []
        if let geminiTools = request.tools {
            for toolWrapper in geminiTools {
                if let funcs = toolWrapper.functionDeclarations {
                    for funcDef in funcs {
                        tools.append(ToolDefinition(function: funcDef))
                    }
                }
            }
        }
        
        return UnifiedPayload(messages: messages, tools: tools)
    }
    
    func parseResponse(data: Data) -> UnifiedPayload? {
        // 1. Try OpenAI format first (LiteLLM compatibility)
        if let openAIPayload = try? JSONDecoder().decode(ChatResponsePayload.self, from: data) {
            let messages = openAIPayload.choices.map { $0.message }
            return UnifiedPayload(messages: messages, tools: [])
        }
        
        // 2. Try Gemini native format
        guard let response = try? JSONDecoder().decode(GeminiResponse.self, from: data) else { return nil }
        
        let messages = (response.candidates ?? []).compactMap { candidate -> ChatMessage? in
            guard let content = candidate.content else { return nil }
            return convertGeminiContent(content)
        }
        
        return UnifiedPayload(messages: messages, tools: [])
    }
    
    private func convertGeminiContent(_ content: GeminiContent) -> ChatMessage {
        var partsText: [String] = []
        var toolCalls: [ToolCall] = []
        
        // Map role: "model" -> "assistant"
        let role = content.role == "model" ? "assistant" : (content.role ?? "user")
        
        if let parts = content.parts {
            for part in parts {
                if let text = part.text {
                    partsText.append(text)
                }
                
                if let fnCall = part.functionCall {
                    // Convert args dict to JSON string
                    let argsString = encodeArgs(fnCall.args)
                    let toolCall = ToolCall(
                        function: FunctionCall(name: fnCall.name, arguments: argsString)
                    )
                    toolCalls.append(toolCall)
                }
                
                if let fnResp = part.functionResponse {
                    // Function Response typically comes from user role
                    let respString = encodeArgs(fnResp.response)
                    partsText.append("Function Response (\(fnResp.name)): \(respString)")
                }
            }
        }
        
        let finalContent = partsText.isEmpty ? nil : partsText.joined(separator: "\n")
        return ChatMessage(role: role, content: finalContent, toolCalls: toolCalls.isEmpty ? nil : toolCalls)
    }
    
    private func encodeArgs(_ args: [String: AnyCodable]?) -> String {
        guard let args = args,
              let data = try? JSONEncoder().encode(args),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}

// MARK: - Claude Parser

class ClaudePayloadParser: PayloadParser {
    
    // Private structs for Claude format
    private struct ClaudeRequest: Codable {
        let messages: [ClaudeMessage]?
        let tools: [ClaudeTool]?
    }
    
    // Claude responses usually come as a single Message object
    private struct ClaudeResponse: Codable {
        let role: String?
        let content: [ClaudeContent]?
        let stop_reason: String?
    }
    
    private struct ClaudeMessage: Codable {
        let role: String
        let content: ClaudeContentWrapper?
    }
    
    // Helper to handle String vs [Object] for Message Content
    private struct ClaudeContentWrapper: Codable {
        let text: String?
        let blocks: [ClaudeContent]?
        
        init(text: String?, blocks: [ClaudeContent]?) {
            self.text = text
            self.blocks = blocks
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                text = str
                blocks = nil
            } else if let arr = try? container.decode([ClaudeContent].self) {
                blocks = arr
                text = nil
            } else {
                text = nil
                blocks = nil
            }
        }
    }
    
    // Helper to handle String vs [Object] for ToolResult Content (Nested)
    private struct ClaudeInnerContentWrapper: Codable {
        let stringValue: String?
        let arrayValue: [ClaudeInnerContent]?
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let str = try? container.decode(String.self) {
                stringValue = str
                arrayValue = nil
            } else if let arr = try? container.decode([ClaudeInnerContent].self) {
                arrayValue = arr
                stringValue = nil
            } else {
                stringValue = nil
                arrayValue = nil
            }
        }
    }
    
    private struct ClaudeInnerContent: Codable {
        let type: String
        let text: String?
    }
    
    private struct ClaudeContent: Codable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
        let input: [String: AnyCodable]? // Tool use input
        let tool_use_id: String?
        // content can be String or Array for tool_result
        let content: ClaudeInnerContentWrapper? 
    }
    
    private struct ClaudeTool: Codable {
        let name: String
        let description: String?
        let input_schema: ParametersDefinition? // Maps closely to OpenAI's parameters
    }
    
    func parseRequest(data: Data) -> UnifiedPayload? {
        guard let request = try? JSONDecoder().decode(ClaudeRequest.self, from: data) else { return nil }
        
        let messages = (request.messages ?? []).map { convertClaudeMessage($0) }
        
        let tools = (request.tools ?? []).map {
            ToolDefinition(function: FunctionDefinition(
                name: $0.name,
                description: $0.description,
                parameters: $0.input_schema
            ))
        }
        
        return UnifiedPayload(messages: messages, tools: tools)
    }
    
    func parseResponse(data: Data) -> UnifiedPayload? {
        // 1. Try OpenAI format first (LiteLLM compatibility)
        if let openAIPayload = try? JSONDecoder().decode(ChatResponsePayload.self, from: data) {
            let messages = openAIPayload.choices.map { $0.message }
            return UnifiedPayload(messages: messages, tools: [])
        }
        
        // 2. Try Claude native format
        guard let response = try? JSONDecoder().decode(ClaudeResponse.self, from: data) else { return nil }
        
        let role = response.role ?? "assistant"
        let msg = convertToChatMessage(role: role, wrapper: ClaudeContentWrapper(text: nil, blocks: response.content))
        
        return UnifiedPayload(messages: [msg], tools: [])
    }
    
    private func convertClaudeMessage(_ msg: ClaudeMessage) -> ChatMessage {
        return convertToChatMessage(role: msg.role, wrapper: msg.content)
    }
    
    private func convertToChatMessage(role: String, wrapper: ClaudeContentWrapper?) -> ChatMessage {
        guard let wrapper = wrapper else { return ChatMessage(role: role, content: "") }
        
        if let text = wrapper.text {
            return ChatMessage(role: role, content: text)
        }
        
        var partsText: [String] = []
        var toolCalls: [ToolCall] = []
        
        if let blocks = wrapper.blocks {
            for block in blocks {
                switch block.type {
                case "text":
                    if let t = block.text { partsText.append(t) }
                case "tool_use":
                    if let name = block.name, let input = block.input {
                        let argsString = encodeArgs(input)
                        let toolCall = ToolCall(
                            id: block.id ?? UUID().uuidString,
                            function: FunctionCall(name: name, arguments: argsString)
                        )
                        toolCalls.append(toolCall)
                    }
                case "tool_result":
                    var resultStr = ""
                    if let innerWrapper = block.content {
                        if let str = innerWrapper.stringValue {
                            resultStr = str
                        } else if let arr = innerWrapper.arrayValue {
                            // Join text content from array
                            resultStr = arr.compactMap { $0.text }.joined(separator: "\n")
                        }
                    }
                    
                    if resultStr.isEmpty { resultStr = "[Empty Tool Result]" }
                    
                    let toolId = block.tool_use_id ?? "?"
                    partsText.append("Tool Result (ID: \(toolId)): \(resultStr)")
                default:
                    break
                }
            }
        }
        
        let finalContent = partsText.isEmpty ? nil : partsText.joined(separator: "\n")
        return ChatMessage(role: role, content: finalContent, toolCalls: toolCalls.isEmpty ? nil : toolCalls)
    }
    
    private func encodeArgs(_ args: [String: AnyCodable]?) -> String {
        guard let args = args,
              let data = try? JSONEncoder().encode(args),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
