import Foundation

public struct Message: Identifiable, Equatable {
    public let id = UUID()
    public let role: Role
    public let content: String
    public let timestamp = Date()
    
    public enum Role: String {
        case user
        case assistant
    }
}
