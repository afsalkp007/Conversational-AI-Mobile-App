import Foundation

public final class RemoteChatLoader: ChatLoader {
    private let url: URL
    private let apiKey: String
    private let client: HTTPClient
    private let model: String

    public enum Error: Swift.Error, Equatable {
        case connectivity
        case invalidData
    }

    public init(url: URL, apiKey: String, model: String = "gpt-3.5-turbo", client: HTTPClient) {
        self.url = url
        self.apiKey = apiKey
        self.model = model
        self.client = client
    }

    public func loadResponse(for messages: [Message]) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatMapper.Error.apiError(statusCode: 401, message: "Missing OpenAI API key.", type: nil)
        }
        
        let request: URLRequest
        do {
            request = try ChatEndpoint.completions(model: model).request(with: messages, baseURL: url, apiKey: apiKey)
        } catch {
            throw Error.invalidData
        }

        let (data, response): (Data, HTTPURLResponse)
        do {
            (data, response) = try await client.execute(request: request)
        } catch {
            throw Error.connectivity
        }

        do {
            return try ChatMapper.map(data, from: response)
        } catch ChatMapper.Error.invalidData {
            throw Error.invalidData
        } catch {
            throw error
        }
    }
}
