
import Foundation

// 代表一个虚拟 API Key
struct VirtualKey: Codable, Identifiable, Hashable {
    var id: String { token }
    let token: String
    let keyName: String
    let keyAlias: String?
    let spend: Double
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case token
        case keyName = "key_name"
        case keyAlias = "key_alias"
        case spend
        case createdAt = "created_at"
    }
}
