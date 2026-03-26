@testable import AIAppFeature
import XCTest

final class ChatMapperTests: XCTestCase {
    
    func test_map_throwsInvalidDataErrorOnNon200HTTPResponseWithInvalidJSON() throws {
        let invalidJSON = Data("invalid json".utf8)
        let response = HTTPURLResponse(url: anyURL(), statusCode: 400, httpVersion: nil, headerFields: nil)!
        
        XCTAssertThrowsError(try ChatMapper.map(invalidJSON, from: response)) { error in
            if case let ChatMapper.Error.apiError(statusCode, message, type) = error {
                XCTAssertEqual(statusCode, 400)
                XCTAssertNil(message)
                XCTAssertNil(type)
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        }
    }
    
    func test_map_throwsAPIErrorOnNon200HTTPResponseWithValidAPIErrorJSON() throws {
        let validAPIErrorJSON = makeAPIError(message: "test message", type: "test_failure")
        let response = HTTPURLResponse(url: anyURL(), statusCode: 401, httpVersion: nil, headerFields: nil)!
        
        XCTAssertThrowsError(try ChatMapper.map(validAPIErrorJSON, from: response)) { error in
            if case let ChatMapper.Error.apiError(statusCode, message, type) = error {
                XCTAssertEqual(statusCode, 401)
                XCTAssertEqual(message, "test message")
                XCTAssertEqual(type, "test_failure")
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        }
    }
    
    func test_map_throwsInvalidDataErrorOn200HTTPResponseWithInvalidJSON() throws {
        let invalidJSON = Data("invalid json".utf8)
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        XCTAssertThrowsError(try ChatMapper.map(invalidJSON, from: response)) { error in
            XCTAssertEqual(error as? ChatMapper.Error, .invalidData)
        }
    }
    
    func test_map_deliversContentOn200HTTPResponseWithValidJSON() throws {
        let validJSON = makeChatCompletionResponse(content: "hello world")
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        let result = try ChatMapper.map(validJSON, from: response)
        
        XCTAssertEqual(result, "hello world")
    }
    
    // MARK: - Helpers
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func makeAPIError(message: String, type: String) -> Data {
        let json: [String: Any] = [
            "error": [
                "message": message,
                "type": type
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeChatCompletionResponse(content: String) -> Data {
        let json: [String: Any] = [
            "choices": [
                [
                    "message": [
                        "content": content
                    ]
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
