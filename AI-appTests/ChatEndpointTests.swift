import AIAppFeature
import XCTest

final class ChatEndpointTests: XCTestCase {
    func test_completions_endpointURL() throws {
        let baseURL = URL(string: "http://any-url.com")!
        let apiKey = "any-key"
        let model = "gpt-model"
        let message = Message(role: .user, content: "test message")
        
        let request = try ChatEndpoint.completions(model: model).request(with: [message], baseURL: baseURL, apiKey: apiKey)
        
        XCTAssertEqual(request.url, baseURL)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer \(apiKey)")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")
        
        XCTAssertNotNil(request.httpBody)
        // Verify we encoded the model properly
        let decoded = try JSONSerialization.jsonObject(with: request.httpBody!, options: []) as? [String: Any]
        XCTAssertEqual(decoded?["model"] as? String, model)
        
        let messages = decoded?["messages"] as? [[String: String]]
        XCTAssertEqual(messages?.first?["role"], "user")
        XCTAssertEqual(messages?.first?["content"], "test message")
    }
}
