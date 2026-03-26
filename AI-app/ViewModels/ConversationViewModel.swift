import Foundation
import Combine

// MARK: - ConversationViewModel
// A slim @ObservableObject responsible only for holding display state.
// All business logic and service coordination lives in ConversationPresentationAdapter.
// User actions are forwarded to `delegate` (set by ConversationUIComposer).
// Presentation updates arrive via the Presenter through view-protocol conformances below.

@MainActor
public class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var state: ChatState = .idle
    @Published var currentTranscript: String = ""

    /// Set by ConversationUIComposer — never set directly in views.
    /// Held strongly because the adapter must outlive the function scope of the Composer.
    var delegate: (any ConversationViewModelDelegate)?

    // MARK: - User actions (forwarded to delegate)

    func startRecording() {
        delegate?.didRequestStartRecording()
    }

    func stopRecording() {
        delegate?.didRequestStopRecording()
    }

    func sendMessage(_ text: String) {
        delegate?.didRequestSendMessage(text)
    }

    func resetConversation() {
        delegate?.didRequestReset()
    }

    func cancelPendingRequest() {
        delegate?.didRequestCancelPendingRequest()
    }

    func requestPermissions() {
        delegate?.didRequestPermissions()
    }
}

// MARK: - View-protocol conformances
// The Presenter drives these methods to update display state.

extension ConversationViewModel: ConversationStateView {
    public func display(_ viewModel: ConversationStateViewModel) {
        state = viewModel.state
    }
}

extension ConversationViewModel: ConversationMessagesView {
    public func display(_ viewModel: ConversationMessagesViewModel) {
        messages = viewModel.messages
    }
}

extension ConversationViewModel: ConversationTranscriptView {
    public func display(_ viewModel: ConversationTranscriptViewModel) {
        currentTranscript = viewModel.transcript
    }
}

