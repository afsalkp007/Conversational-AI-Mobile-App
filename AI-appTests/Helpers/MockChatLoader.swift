//
//  MockChatLoader.swift
//  AI-app
//
//  Created by Mohamed Afsal on 26/03/2026.
//

import AI_app

final class MockChatLoader: ChatLoader {
    indirect enum Behavior {
        case succeed(String)
        case fail(Error)
        case delay(ms: UInt64, then: Behavior)
    }

    var behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func loadResponse(for messages: [Message]) async throws -> String {
        switch behavior {
        case .succeed(let text):
            return text
        case .fail(let error):
            throw error
        case .delay(let ms, let then):
            try await Task.sleep(nanoseconds: ms * 1_000_000)
            self.behavior = then
            return try await loadResponse(for: messages)
        }
    }
}
