import Foundation

struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp = Date()
    
    enum Role: String {
        case user
        case assistant
    }
}
