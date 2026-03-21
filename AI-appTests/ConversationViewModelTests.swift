@testable import AI_app
import XCTest
import Combine

final class MockOpenAIService: OpenAIServicing {
    enum Behavior {
        case succeed(String)
        case fail(Error)
        case delay(ms: UInt64, then: Behavior)
    }

    var behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func sendMessage(messages: [Message]) async throws -> String {
        switch behavior {
        case .succeed(let text):
            return text
        case .fail(let error):
            throw error
        case .delay(let ms, let then):
            try await Task.sleep(nanoseconds: ms * 1_000_000)
            self.behavior = then
            return try await sendMessage(messages: messages)
        }
    }
}

final class MockSpeechRecognizer: SpeechRecognizing {
    @Published var transcript: String = ""
    private let transcriptSubject = CurrentValueSubject<String, Never>("")

    var transcriptPublisher: AnyPublisher<String, Never> {
        transcriptSubject.eraseToAnyPublisher()
    }

    func requestAuthorization() {}

    func startRecording() throws {
        transcript = ""
        transcriptSubject.send("")
    }

    func stopRecording() {}

    func setTranscript(_ text: String) {
        transcript = text
        transcriptSubject.send(text)
    }
}

final class MockSpeechSynthesizer: SpeechSynthesizing {
    var onComplete: (() -> Void)?
    private(set) var spoken: [String] = []

    func speak(_ text: String) {
        spoken.append(text)
    }

    func stop() {}

    func complete() {
        onComplete?()
    }
}

final class ConversationViewModelTests: XCTestCase {
    @MainActor
    private func makeViewModel(
        aiBehavior: MockOpenAIService.Behavior = .succeed("Hi!"),
        recognizer: MockSpeechRecognizer = MockSpeechRecognizer(),
        synthesizer: MockSpeechSynthesizer = MockSpeechSynthesizer()
    ) -> (ConversationViewModel, MockSpeechRecognizer, MockSpeechSynthesizer) {
        let vm = ConversationViewModel(
            openAIService: MockOpenAIService(behavior: aiBehavior),
            speechRecognizer: recognizer,
            speechSynthesizer: synthesizer
        )
        return (vm, recognizer, synthesizer)
    }
    
    @MainActor func testInitialState() {
        let (viewModel, _, _) = makeViewModel()
        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.messages.isEmpty)
    }
    
    @MainActor func testSendMessageUpdatesStateImmediately() async {
        let (viewModel, _, _) = makeViewModel(aiBehavior: .delay(ms: 50, then: .succeed("Hello back")))
        let testMessage = "Hello"
        viewModel.sendMessage(testMessage)
        
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.content, testMessage)
        XCTAssertEqual(viewModel.messages.first?.role, .user)
        
        // State should be processing immediately after sending
        XCTAssertEqual(viewModel.state, .processing)

        // Allow async task to finish and append assistant response.
        try? await Task.sleep(nanoseconds: 80 * 1_000_000)
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertEqual(viewModel.messages.last?.content, "Hello back")
        XCTAssertEqual(viewModel.state, .speaking)
    }

    @MainActor func testSpeakingCompletesToIdle() async {
        let (viewModel, _, synthesizer) = makeViewModel(aiBehavior: .succeed("Done"))
        viewModel.sendMessage("Hi")

        await Task.yield()
        XCTAssertEqual(viewModel.state, .speaking)
        synthesizer.complete()
        XCTAssertEqual(viewModel.state, .idle)
    }

    @MainActor func testEmptyTranscriptStopRecordingDoesNotSend() {
        let (viewModel, recognizer, _) = makeViewModel()
        recognizer.setTranscript(" ")
        viewModel.stopRecording()
        XCTAssertTrue(viewModel.messages.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
    }
}
