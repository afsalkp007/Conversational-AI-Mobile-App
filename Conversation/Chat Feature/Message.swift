import Foundation

public struct Message: Identifiable, Equatable {
    public let id = UUID()
    public let role: Role
    public let content: String
    public let timestamp = Date()

    public init(role: Role, content: String) {
        self.role = role
        self.content = content
    }
    
    public enum Role: String {
        case user
        case assistant
    }
}
