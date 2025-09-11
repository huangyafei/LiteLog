
import Foundation

// MARK: - API Service
class APIService {
    
    private let baseURL: String
    private let adminApiKey: String
    private let session: URLSession
    
    init(baseURL: String, adminApiKey: String) {
        self.baseURL = baseURL
        self.adminApiKey = adminApiKey
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: configuration)
    }
    
    func fetchVirtualKeys() async throws -> [VirtualKey] {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        urlComponents.path = "/key/list"
        urlComponents.queryItems = [
            URLQueryItem(name: "return_full_object", value: "true"),
            URLQueryItem(name: "sort_order", value: "desc"),
            URLQueryItem(name: "size", value: "100") // Per documentation suggestion
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(adminApiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)

        #if DEBUG
        print("--- API Response for \(url.path) ---")
        if let dataString = String(data: data, encoding: .utf8) {
            print(dataString)
        } else {
            print("Could not convert data to UTF-8 string.")
        }
        print("--- End API Response ---")
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        guard !data.isEmpty else {
            return []
        }
        
        let decoder = JSONDecoder()
        let keyResponse = try decoder.decode(VirtualKeyResponse.self, from: data)
        return keyResponse.keys
    }
    
    func fetchLogs(for apiKeyToken: String) async throws -> [LogEntry] {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        urlComponents.path = "/spend/logs/ui"
        
        // Default to last 24 hours as per documentation
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-24 * 60 * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        urlComponents.queryItems = [
            URLQueryItem(name: "api_key", value: apiKeyToken),
            URLQueryItem(name: "start_date", value: formatter.string(from: startDate)),
            URLQueryItem(name: "end_date", value: formatter.string(from: endDate)),
            URLQueryItem(name: "page_size", value: "50") // Per documentation suggestion
        ]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(adminApiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)

        #if DEBUG
        print("--- API Response for \(url.path) ---")
        if let dataString = String(data: data, encoding: .utf8) {
            print(dataString)
        } else {
            print("Could not convert data to UTF-8 string.")
        }
        print("--- End API Response ---")
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.requestFailed(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
        
        guard !data.isEmpty else {
            return []
        }
        
        let decoder = JSONDecoder()
        let logResponse = try decoder.decode(LogResponse.self, from: data)
        return logResponse.data
    }
}

// MARK: - Response Wrappers & Error Enum

private struct VirtualKeyResponse: Codable {
    let keys: [VirtualKey]
}

private struct LogResponse: Codable {
    let data: [LogEntry]
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The provided Base URL is invalid."
        case .requestFailed(let statusCode):
            if statusCode == 401 {
                return "Authentication failed. Please check your Admin API Key."
            }
            return "The API request failed with status code: \(statusCode)."
        case .decodingFailed(let error):
            return "Failed to decode the server response: \(error.localizedDescription)"
        }
    }
}
