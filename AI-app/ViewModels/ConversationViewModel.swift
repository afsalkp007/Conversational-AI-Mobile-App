import Foundation
import Combine

@MainActor
class ConversationViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var state: ChatState = .idle
    @Published var currentTranscript: String = ""
    
    // Dependencies
    private let openAIService: any OpenAIServicing
    private let speechRecognizer: any SpeechRecognizing
    private let speechSynthesizer: any SpeechSynthesizing
    
    private var cancellables = Set<AnyCancellable>()
    private var requestTask: Task<Void, Never>?
    
    init(
        openAIService: any OpenAIServicing,
        speechRecognizer: any SpeechRecognizing = SpeechRecognizer(),
        speechSynthesizer: any SpeechSynthesizing = SpeechSynthesizer()
    ) {
        self.openAIService = openAIService
        self.speechRecognizer = speechRecognizer
        self.speechSynthesizer = speechSynthesizer
        setupBindings()
    }

    convenience init() {
        let apiKey = AppSecrets.openAIAPIKey ?? ""
        self.init(openAIService: OpenAIService(apiKey: apiKey))
        if apiKey.isEmpty {
            self.state = .error("Missing OpenAI API key. See README for setup.")
        }
    }
    
    private func setupBindings() {
        // Update currentTranscript live as user speaks
        speechRecognizer.transcriptPublisher
            .assign(to: \.currentTranscript, on: self)
            .store(in: &cancellables)
            
        // When speech synthesizer finishes, go back to idle
        speechSynthesizer.onComplete = { [weak self] in
            DispatchQueue.main.async {
                self?.state = .idle
            }
        }
    }
    
    func startRecording() {
        // Stop any current speech
        speechSynthesizer.stop()
        cancelPendingRequest()
        
        do {
            try speechRecognizer.startRecording()
            state = .listening
        } catch {
            state = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        speechRecognizer.stopRecording()
        let text = speechRecognizer.transcript
        
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 else {
            state = .idle
            return
        }
        
        sendMessage(text)
    }
    
    func sendMessage(_ text: String) {
        if case .error = state, AppSecrets.openAIAPIKey == nil {
            state = .error("Missing OpenAI API key. See README for setup.")
            return
        }
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        state = .processing
        
        requestTask = Task {
            do {
                let responseText = try await openAIService.sendMessage(messages: messages)
                try Task.checkCancellation()
                let aiMessage = Message(role: .assistant, content: responseText)
                messages.append(aiMessage)
                
                state = .speaking
                speechSynthesizer.speak(responseText)
            } catch {
                if Task.isCancelled {
                    state = .idle
                } else {
                    state = .error(error.localizedDescription)
                }
            }
        }
    }

    func resetConversation() {
        cancelPendingRequest()
        speechSynthesizer.stop()
        messages.removeAll()
        currentTranscript = ""
        state = .idle
    }

    func cancelPendingRequest() {
        requestTask?.cancel()
        requestTask = nil
        if state == .processing {
            state = .idle
        }
    }
    
    func requestPermissions() {
        speechRecognizer.requestAuthorization()
    }
}
