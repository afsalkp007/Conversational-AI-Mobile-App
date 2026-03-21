import Foundation

class OpenAIService: OpenAIServicing {
    private let apiKey: String
    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let session: URLSession
    
    init(apiKey: String, session: URLSession? = nil) {
        self.apiKey = apiKey
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            self.session = URLSession(configuration: config)
        }
    }
    
    func sendMessage(messages: [Message]) async throws -> String {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAIError.missingAPIKey
        }

        let apiMessages = messages.map { ChatCompletionRequest.Message(role: $0.role.rawValue, content: $0.content) }
        let body = ChatCompletionRequest(model: "gpt-3.5-turbo", messages: apiMessages)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw OpenAIError.encodingFailed(underlying: error)
        }

        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let apiError = (try? JSONDecoder().decode(OpenAIAPIErrorEnvelope.self, from: data))?.error
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: apiError?.message, type: apiError?.type)
        }

        do {
            let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            let content = result.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return content
        } catch {
            throw OpenAIError.decodingFailed(underlying: error)
        }
    }
}

enum OpenAIError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case apiError(statusCode: Int, message: String?, type: String?)
    case encodingFailed(underlying: Error)
    case decodingFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Missing OpenAI API key."
        case .invalidResponse:
            return "Invalid response from server."
        case .apiError(let statusCode, let message, _):
            let detail = message?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let detail, !detail.isEmpty {
                return "OpenAI API error (\(statusCode)): \(detail)"
            }
            return "OpenAI API error (\(statusCode))."
        case .encodingFailed:
            return "Failed to encode request."
        case .decodingFailed:
            return "Failed to decode response."
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

private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct OpenAIAPIErrorEnvelope: Decodable {
    struct APIError: Decodable {
        let message: String?
        let type: String?
    }

    let error: APIError
}
