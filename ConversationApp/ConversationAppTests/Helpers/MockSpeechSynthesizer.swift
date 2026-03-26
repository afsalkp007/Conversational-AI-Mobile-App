//
//  MockSpeechSynthesizer.swift
//  ConversationApp
//
//  Created by Mohamed Afsal on 26/03/2026.
//

import Conversation

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
