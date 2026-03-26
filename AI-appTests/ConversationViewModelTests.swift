@testable import AIAppFeature
import XCTest
import Combine

// MARK: - Test Doubles

final class ConversationViewModelTests: XCTestCase {
    @MainActor
    private func makeViewModel(
        aiBehavior: MockChatLoader.Behavior = .succeed("Hi!"),
        recognizer: MockSpeechRecognizer = MockSpeechRecognizer(),
        synthesizer: MockSpeechSynthesizer = MockSpeechSynthesizer()
    ) -> (ConversationViewModel, MockSpeechRecognizer, MockSpeechSynthesizer) {
        let vm = ConversationUIComposer.conversationComposedWith(
            aiService: MockChatLoader(behavior: aiBehavior),
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

        // Wait deterministically for the state to bounce from processing to speaking
        let exp = expectation(description: "Wait for state transition to speaking")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$state.sink { state in
            if state == .speaking {
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        cancellable?.cancel()
        
        XCTAssertEqual(viewModel.messages.count, 2)
        XCTAssertEqual(viewModel.messages.last?.role, .assistant)
        XCTAssertEqual(viewModel.messages.last?.content, "Hello back")
        XCTAssertEqual(viewModel.state, .speaking)
    }

    @MainActor func testSpeakingCompletesToIdle() async {
        let (viewModel, _, synthesizer) = makeViewModel(aiBehavior: .succeed("Done"))
        viewModel.sendMessage("Hi")

        // Wait deterministically for the state to bounce from processing to speaking
        let exp = expectation(description: "Wait for state transition to speaking")
        var cancellable: AnyCancellable?
        cancellable = viewModel.$state.sink { state in
            if state == .speaking {
                exp.fulfill()
            }
        }
        
        await fulfillment(of: [exp], timeout: 1.0)
        cancellable?.cancel()
        
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
