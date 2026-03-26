@testable import AI_app
import XCTest

final class RemoteChatLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_loadResponse_requestsDataFromURL() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        client.stub(result: .success((anyData(), anyHTTPURLResponse())))
        
        _ = try? await sut.loadResponse(for: [anyMessage()])
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadResponse_deliversErrorOnClientError() async {
        let (sut, client) = makeSUT()
        client.stub(result: .failure(anyNSError()))
        
        await expect(sut, toCompleteWith: .failure(.connectivity))
    }
    
    func test_loadResponse_deliversErrorOnMapperError() async {
        let (sut, client) = makeSUT()
        let invalidJSON = Data("invalid json".utf8)
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        client.stub(result: .success((invalidJSON, response)))
        
        await expect(sut, toCompleteWith: .failure(.invalidData))
    }
    
    func test_loadResponse_deliversContentOn200HTTPResponseWithValidJSON() async throws {
        let (sut, client) = makeSUT()
        let validJSON = makeChatCompletionResponse(content: "hello world")
        let response = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        client.stub(result: .success((validJSON, response)))
        
        let result = try await sut.loadResponse(for: [anyMessage()])
        
        XCTAssertEqual(result, "hello world")
    }
    
    func test_loadResponse_deliversAPIErrorOnMissingAPIKey() async {
        let (sut, _) = makeSUT(apiKey: "   ")
        
        do {
            _ = try await sut.loadResponse(for: [anyMessage()])
            XCTFail("Expected API error, got success")
        } catch let error as ChatMapper.Error {
            if case let .apiError(statusCode, message, _) = error {
                XCTAssertEqual(statusCode, 401)
                XCTAssertEqual(message, "Missing OpenAI API key.")
            } else {
                XCTFail("Expected apiError, got \(error)")
            }
        } catch {
            XCTFail("Expected ChatMapper.Error, got \(error)")
        }
    }

    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "https://a-url.com")!, apiKey: String = "valid-key", file: StaticString = #file, line: UInt = #line) -> (sut: RemoteChatLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteChatLoader(url: url, apiKey: apiKey, client: client)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
    }
    
    private func expect(_ sut: RemoteChatLoader, toCompleteWith expectedResult: Result<String, RemoteChatLoader.Error>, file: StaticString = #file, line: UInt = #line) async {
        do {
            let receivedContent = try await sut.loadResponse(for: [anyMessage()])
            if case let .success(expectedContent) = expectedResult {
                XCTAssertEqual(receivedContent, expectedContent, file: file, line: line)
            } else {
                XCTFail("Expected \(expectedResult) but got success with \(receivedContent)", file: file, line: line)
            }
        } catch let receivedError as RemoteChatLoader.Error {
            if case let .failure(expectedError) = expectedResult {
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            } else {
                XCTFail("Expected \(expectedResult) but got failure with \(receivedError)", file: file, line: line)
            }
        } catch {
            XCTFail("Expected \(expectedResult) but got failure with \(error)", file: file, line: line)
        }
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func anyNSError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
    
    private func anyMessage() -> Message {
        return Message(role: .user, content: "test message")
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
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, result: Result<(Data, HTTPURLResponse), Error>)]()
        
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
        
        private var stubbedResult: Result<(Data, HTTPURLResponse), Error>?
        
        func stub(result: Result<(Data, HTTPURLResponse), Error>) {
            stubbedResult = result
        }
        
        func execute(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let result = stubbedResult ?? .failure(NSError(domain: "no stub", code: 0))
            messages.append((request.url!, result))
            return try result.get()
        }
    }
}
