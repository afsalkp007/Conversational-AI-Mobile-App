import Foundation

public enum ChatEndpoint {
    case completions(model: String)

    public func request(with messages: [Message], baseURL: URL, apiKey: String) throws -> URLRequest {
        switch self {
        case .completions(let model):
            var request = URLRequest(url: baseURL)
            request.httpMethod = "POST"
            request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let apiMessages = messages.map { ChatCompletionRequest.Message(role: $0.role.rawValue, content: $0.content) }
            let body = ChatCompletionRequest(model: model, messages: apiMessages)
            request.httpBody = try JSONEncoder().encode(body)
            
            return request
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    struct Message: Encodable {
        let role: String
        let content: String
    }
    let model: String
    let messages: [Message]
}
