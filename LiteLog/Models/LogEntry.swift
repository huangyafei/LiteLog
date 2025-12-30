
import Foundation

// 代表一条日志记录
struct LogEntry: Codable, Identifiable, Hashable {
    var id: String { requestId }
    
    let requestId: String
    let status: String
    let model: String
    let startTime: String
    let endTime: String
    let spend: Double
    let totalTokens: Int?
    let promptTokens: Int?
    let completionTokens: Int?
    let user: String?
    let metadata: [String: AnyCodable]?
    let cacheHit: String?
    let customLlmProvider: String?
    let apiBase: String?

    // 将原始 JSON 数据存储为 Data
    let requestPayload: Data?
    let responsePayload: Data?

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case status, model, user, metadata
        case startTime = "startTime"
        case endTime = "endTime"
        case spend
        case totalTokens = "total_tokens"
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case cacheHit = "cache_hit"
        case customLlmProvider = "custom_llm_provider"
        case apiBase = "api_base"
        case requestPayload = "proxy_server_request"
        case responsePayload = "response"
    }
    
    // Custom decoder to handle dynamic JSON objects by storing them as Data
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestId = try container.decode(String.self, forKey: .requestId)
        status = try container.decode(String.self, forKey: .status)
        model = try container.decode(String.self, forKey: .model)
        startTime = try container.decode(String.self, forKey: .startTime)
        endTime = try container.decode(String.self, forKey: .endTime)
        spend = try container.decode(Double.self, forKey: .spend)
        totalTokens = try container.decodeIfPresent(Int.self, forKey: .totalTokens)
        promptTokens = try container.decodeIfPresent(Int.self, forKey: .promptTokens)
        completionTokens = try container.decodeIfPresent(Int.self, forKey: .completionTokens)
        user = try container.decodeIfPresent(String.self, forKey: .user)
        metadata = try container.decodeIfPresent([String: AnyCodable].self, forKey: .metadata)
        cacheHit = try container.decodeIfPresent(String.self, forKey: .cacheHit)
        customLlmProvider = try container.decodeIfPresent(String.self, forKey: .customLlmProvider)
        apiBase = try container.decodeIfPresent(String.self, forKey: .apiBase)

        // Encode the JSON objects for request and response back to Data
        if let requestJSON = try? container.decodeIfPresent(AnyCodable.self, forKey: .requestPayload) {
            let encoder = JSONEncoder()
            requestPayload = try? encoder.encode(requestJSON)
        } else {
            requestPayload = nil
        }

        if let responseJSON = try? container.decodeIfPresent(AnyCodable.self, forKey: .responsePayload) {
            let encoder = JSONEncoder()
            responsePayload = try? encoder.encode(responseJSON)
        } else {
            responsePayload = nil
        }
    }
}

