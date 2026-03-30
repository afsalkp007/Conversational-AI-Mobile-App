import Foundation

// MARK: - ConversationUIComposer
// Wires all layers together and returns a ready-to-use ViewModel.
// This is the single place that knows about concrete types.
// Analogous to FeedUIComposer in the Feed App.

@MainActor
public final class ConversationUIComposer {
    private init() {}

    public static func conversationComposedWith(
        aiService: any ChatLoader,
        speechRecognizer: any SpeechRecognizing,
        speechSynthesizer: any SpeechSynthesizing
    ) -> ConversationViewModel {
        let viewModel = ConversationViewModel()

        let adapter = ConversationPresentationAdapter(
            aiService: aiService,
            speechRecognizer: speechRecognizer,
            speechSynthesizer: speechSynthesizer
        )

        let presenter = ConversationPresenter(
            stateView: WeakRefVirtualProxy(viewModel),
            messagesView: WeakRefVirtualProxy(viewModel),
            transcriptView: WeakRefVirtualProxy(viewModel)
        )

        adapter.presenter = presenter
        viewModel.delegate = adapter

        return viewModel
    }
}
