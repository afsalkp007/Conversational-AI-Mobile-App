import Foundation

public protocol ChatLoader {
    func loadResponse(for messages: [Message]) async throws -> String
}
