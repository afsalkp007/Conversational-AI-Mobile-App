import Foundation

public enum ChatMapper {
    public enum Error: Swift.Error, Equatable {
        case invalidData
        case apiError(statusCode: Int, message: String?, type: String?)
    }
    
    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> String {
        guard response.statusCode == 200 else {
            let apiError = (try? JSONDecoder().decode(OpenAIAPIErrorEnvelope.self, from: data))?.error
            throw Error.apiError(statusCode: response.statusCode, message: apiError?.message, type: apiError?.type)
        }
        
        guard let result = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
              let content = result.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw Error.invalidData
        }
        
        return content
    }
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
