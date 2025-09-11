
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
        return false
    }

    func hash(into hasher: inout Hasher) {
        // This is a simplified hash. A full implementation is complex.
    }
}
