import Foundation
import Combine

// MARK: - Speech

public protocol SpeechRecognizing: AnyObject, ObservableObject {
    var transcriptPublisher: AnyPublisher<String, Never> { get }
    var transcript: String { get }

    func requestAuthorization()
    func startRecording() throws
    func stopRecording()
}

public protocol SpeechSynthesizing: AnyObject {
    var onComplete: (() -> Void)? { get set }
    func speak(_ text: String)
    func stop()
}
