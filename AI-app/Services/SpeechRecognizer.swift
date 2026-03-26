import Foundation
import Combine
import Speech
import AVFoundation

class SpeechRecognizer: ObservableObject, SpeechRecognizing {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    @Published var transcript: String = ""
    @Published var isRecording = false

    var transcriptPublisher: AnyPublisher<String, Never> {
        $transcript.eraseToAnyPublisher()
    }

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    print("Speech recognition authorized")
                case .denied, .restricted, .notDetermined:
                    print("Speech recognition not authorized")
                @unknown default:
                    break
                }
            }
        }
    }

    func startRecording() throws {
        guard !audioEngine.isRunning else { return }

        // 1. Cancel any in-flight task/request — does NOT touch inputNode.
        cancelSession()

        // 2. Activate the audio session BEFORE accessing inputNode.
        //    Accessing inputNode before session activation causes iOS to cache
        //    a zero-sampleRate format for the node, which crashes installTap.
        try AudioSessionManager.shared.activateForRecording()

        // 3. Now it is safe to access the input node.
        let inputNode = audioEngine.inputNode

        // 4. Always remove any lingering tap from a previous session.
        //    removeTap(onBus:) is safe to call even if no tap is installed.
        inputNode.removeTap(onBus: 0)

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        // On the simulator there is no real microphone; guard prevents crash.
        guard recordingFormat.sampleRate > 0 else {
            throw RecordingError.invalidAudioFormat
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
                if result.isFinal {
                    self.stopRecording()
                }
            } else if error != nil {
                self.stopRecording()
            }
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        try audioEngine.start()
        DispatchQueue.main.async {
            self.isRecording = true
            self.transcript = ""
        }
    }

    func stopRecording() {
        // Do NOT guard on audioEngine.isRunning — the engine can stop naturally
        // (recognition task finishes / audio interruption) while the tap is still
        // installed. Skipping teardown in that case leaves a stale tap which
        // causes the IsFormatSampleRateAndChannelCountValid crash next session.
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        cancelSession()
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

    // MARK: - Private

    /// Cancels in-flight speech task/request without touching the audio engine or inputNode.
    private func cancelSession() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case invalidAudioFormat

    var errorDescription: String? {
        "Microphone is unavailable. This feature requires a real device or a simulator with a connected microphone."
    }
}
