import Foundation

// MARK: - WeakRefVirtualProxy
// Breaks strong-reference cycles between Presenter ↔ ViewModel.
// Analogous to Feed App's WeakRefVirtualProxy.

final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?

    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: ConversationStateView where T: ConversationStateView {
    func display(_ viewModel: ConversationStateViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: ConversationMessagesView where T: ConversationMessagesView {
    func display(_ viewModel: ConversationMessagesViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: ConversationTranscriptView where T: ConversationTranscriptView {
    func display(_ viewModel: ConversationTranscriptViewModel) {
        object?.display(viewModel)
    }
}
