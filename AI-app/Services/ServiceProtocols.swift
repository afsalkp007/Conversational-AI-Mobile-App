import Foundation
import Combine

protocol OpenAIServicing {
    func sendMessage(messages: [Message]) async throws -> String
}

protocol SpeechRecognizing: AnyObject, ObservableObject {
    var transcriptPublisher: AnyPublisher<String, Never> { get }
    var transcript: String { get }

    func requestAuthorization()
    func startRecording() throws
    func stopRecording()
}

protocol SpeechSynthesizing: AnyObject {
    var onComplete: (() -> Void)? { get set }
    func speak(_ text: String)
    func stop()
}

