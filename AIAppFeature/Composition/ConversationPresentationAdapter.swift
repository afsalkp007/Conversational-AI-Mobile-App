import Foundation
import Combine

// MARK: - ConversationViewModelDelegate
// Protocol through which the ViewModel triggers actions.
// Analogous to FeedViewControllerDelegate in Feed App.

protocol ConversationViewModelDelegate: AnyObject {
    func didRequestStartRecording()
    func didRequestStopRecording()
    func didRequestSendMessage(_ text: String)
    func didRequestReset()
    func didRequestCancelPendingRequest()
    func didRequestPermissions()
}

// MARK: - ConversationPresentationAdapter
// Bridges user-driven ViewModel actions → async service calls → Presenter events.
// Analogous to FeedLoaderPresentationAdapter in Feed App.

@MainActor
final class ConversationPresentationAdapter: ConversationViewModelDelegate {
    private let aiService: any ChatLoader
    private let speechRecognizer: any SpeechRecognizing
    private let speechSynthesizer: any SpeechSynthesizing
    var presenter: ConversationPresenter?

    private var messages: [Message] = []
    private var requestTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(
        aiService: any ChatLoader,
        speechRecognizer: any SpeechRecognizing,
        speechSynthesizer: any SpeechSynthesizing
    ) {
        self.aiService = aiService
        self.speechRecognizer = speechRecognizer
        self.speechSynthesizer = speechSynthesizer
        setupBindings()
    }

    private func setupBindings() {
        // Forward live transcript updates to Presenter
        speechRecognizer.transcriptPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.presenter?.didUpdateTranscript(text)
            }
            .store(in: &cancellables)

        // When synthesizer finishes, notify Presenter
        speechSynthesizer.onComplete = { [weak self] in
            self?.presenter?.didFinishSpeaking()
        }
    }

    // MARK: ConversationViewModelDelegate

    func didRequestStartRecording() {
        speechSynthesizer.stop()
        cancelRequest()

        do {
            try speechRecognizer.startRecording()
            presenter?.didStartListening()
        } catch {
            presenter?.didFinishWithError(error)
        }
    }

    func didRequestStopRecording() {
        speechRecognizer.stopRecording()
        let text = speechRecognizer.transcript

        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            presenter?.didCancelRequest()
            return
        }

        sendMessage(text)
    }

    func didRequestSendMessage(_ text: String) {
        sendMessage(text)
    }

    func didRequestReset() {
        cancelRequest()
        speechSynthesizer.stop()
        messages.removeAll()
        presenter?.didReset()
    }

    func didRequestCancelPendingRequest() {
        cancelRequest()
    }

    func didRequestPermissions() {
        speechRecognizer.requestAuthorization()
    }

    // MARK: Private

    private func sendMessage(_ text: String) {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        presenter?.didStartProcessing(messages: messages)

        requestTask = Task {
            do {
                let responseText = try await aiService.loadResponse(for: messages)
                try Task.checkCancellation()
                let aiMessage = Message(role: .assistant, content: responseText)
                messages.append(aiMessage)
                presenter?.didReceiveResponse(messages: messages)
                speechSynthesizer.speak(responseText)
            } catch {
                guard !Task.isCancelled else { return }
                presenter?.didFinishWithError(error)
            }
        }
    }

    private func cancelRequest() {
        requestTask?.cancel()
        requestTask = nil
    }
}
