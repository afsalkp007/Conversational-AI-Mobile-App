//
//  MockSpeechRecognizer.swift
//  AI-app
//
//  Created by Mohamed Afsal on 26/03/2026.
//

import AI_app
import Combine

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
