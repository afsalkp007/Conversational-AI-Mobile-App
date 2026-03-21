import Foundation

enum ChatState: Equatable {
    case idle
    case listening
    case processing
    case speaking
    case error(String)
    
    var statusText: String {
        switch self {
        case .idle: return "Tap to Speak"
        case .listening: return "Listening..."
        case .processing: return "Thinking..."
        case .speaking: return "Speaking..."
        case .error(let message): return "Error: \(message)"
        }
    }
}
