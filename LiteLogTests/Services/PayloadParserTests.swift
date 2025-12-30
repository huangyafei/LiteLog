
import XCTest
@testable import LiteLog

final class PayloadParserTests: XCTestCase {
    
    // MARK: - Gemini Tests
    
    func testGeminiRequestParsing() throws {
        let json = """
        {
          "contents": [
            {
              "role": "user",
              "parts": [
                { "text": "What is the weather in Boston?" }
              ]
            }
          ],
          "tools": [
            {
              "functionDeclarations": [
                {
                  "name": "get_weather",
                  "description": "Get weather",
                  "parameters": {
                    "type": "object",
                    "properties": {
                      "location": { "type": "string" }
                    }
                  }
                }
              ]
            }
          ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let parser = GeminiPayloadParser()
        let payload = parser.parseRequest(data: data)
        
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.messages.count, 1)
        XCTAssertEqual(payload?.messages.first?.role, "user")
        XCTAssertEqual(payload?.messages.first?.content, "What is the weather in Boston?")
        
        XCTAssertEqual(payload?.tools.count, 1)
        XCTAssertEqual(payload?.tools.first?.function.name, "get_weather")
    }
    
    func testGeminiResponseParsing() throws {
        let json = """
        {
          "candidates": [
            {
              "content": {
                "role": "model",
                "parts": [
                  {
                    "functionCall": {
                      "name": "get_weather",
                      "args": { "location": "Boston" }
                    }
                  }
                ]
              }
            }
          ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let parser = GeminiPayloadParser()
        let payload = parser.parseResponse(data: data)
        
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.messages.count, 1)
        let msg = payload?.messages.first
        XCTAssertEqual(msg?.role, "assistant")
        XCTAssertNil(msg?.content)
        XCTAssertEqual(msg?.toolCalls?.count, 1)
        XCTAssertEqual(msg?.toolCalls?.first?.function.name, "get_weather")
    }
    
    // MARK: - Claude Tests
    
    func testClaudeRequestParsing() throws {
        let json = """
        {
          "messages": [
            { "role": "user", "content": "Hello" }
          ],
          "tools": [
            {
              "name": "get_weather",
              "input_schema": {
                "type": "object",
                "properties": { "location": { "type": "string" } }
              }
            }
          ]
        }
        """
        
        let data = json.data(using: .utf8)!
        let parser = ClaudePayloadParser()
        let payload = parser.parseRequest(data: data)
        
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.messages.count, 1)
        XCTAssertEqual(payload?.tools.count, 1)
        XCTAssertEqual(payload?.tools.first?.function.name, "get_weather")
    }
    
    func testClaudeResponseParsing() throws {
        let json = """
        {
          "role": "assistant",
          "content": [
            {
              "type": "tool_use",
              "id": "tool_123",
              "name": "get_weather",
              "input": { "location": "SF" }
            }
          ],
          "stop_reason": "tool_use"
        }
        """
        
        let data = json.data(using: .utf8)!
        let parser = ClaudePayloadParser()
        let payload = parser.parseResponse(data: data)
        
        XCTAssertNotNil(payload)
        XCTAssertEqual(payload?.messages.count, 1)
        let msg = payload?.messages.first
        XCTAssertEqual(msg?.toolCalls?.count, 1)
        XCTAssertEqual(msg?.toolCalls?.first?.function.name, "get_weather")
        XCTAssertEqual(msg?.toolCalls?.first?.id, "tool_123")
    }
}
