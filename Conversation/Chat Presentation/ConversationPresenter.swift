import Foundation

// MARK: - View-protocol contracts
// (analogous to FeedLoadingView / FeedErrorView / FeedView in Feed App)

public protocol ConversationStateView: AnyObject {
    func display(_ viewModel: ConversationStateViewModel)
}

public protocol ConversationMessagesView: AnyObject {
    func display(_ viewModel: ConversationMessagesViewModel)
}

public protocol ConversationTranscriptView: AnyObject {
    func display(_ viewModel: ConversationTranscriptViewModel)
}

// MARK: - View-model structs (pure data, no SwiftUI)

public struct ConversationStateViewModel {
    public let state: ChatState

    public init(state: ChatState) {
        self.state = state
    }
}

public struct ConversationMessagesViewModel {
    public let messages: [Message]

    public init(messages: [Message]) {
        self.messages = messages
    }
}

public struct ConversationTranscriptViewModel {
    public let transcript: String

    public init(transcript: String) {
        self.transcript = transcript
    }
}

// MARK: - Presenter
// Receives domain events and drives view-protocol contracts.
// No UIKit / SwiftUI dependency — analogous to FeedPresenter.

public final class ConversationPresenter {
    private let stateView: ConversationStateView
    private let messagesView: ConversationMessagesView
    private let transcriptView: ConversationTranscriptView

    public init(
        stateView: ConversationStateView,
        messagesView: ConversationMessagesView,
        transcriptView: ConversationTranscriptView
    ) {
        self.stateView = stateView
        self.messagesView = messagesView
        self.transcriptView = transcriptView
    }

    public func didStartListening() {
        stateView.display(ConversationStateViewModel(state: .listening))
    }

    public func didUpdateTranscript(_ text: String) {
        transcriptView.display(ConversationTranscriptViewModel(transcript: text))
    }

    public func didStartProcessing(messages: [Message]) {
        stateView.display(ConversationStateViewModel(state: .processing))
        messagesView.display(ConversationMessagesViewModel(messages: messages))
    }

    public func didReceiveResponse(messages: [Message]) {
        stateView.display(ConversationStateViewModel(state: .speaking))
        messagesView.display(ConversationMessagesViewModel(messages: messages))
    }

    public func didFinishSpeaking() {
        stateView.display(ConversationStateViewModel(state: .idle))
    }

    public func didFinishWithError(_ error: Error) {
        stateView.display(ConversationStateViewModel(state: .error(error.localizedDescription)))
    }

    public func didReset() {
        stateView.display(ConversationStateViewModel(state: .idle))
        messagesView.display(ConversationMessagesViewModel(messages: []))
        transcriptView.display(ConversationTranscriptViewModel(transcript: ""))
    }

    public func didCancelRequest() {
        stateView.display(ConversationStateViewModel(state: .idle))
    }
}
