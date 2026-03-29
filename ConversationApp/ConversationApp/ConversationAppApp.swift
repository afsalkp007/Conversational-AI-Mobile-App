//
//  ConversationAppApp.swift
//  ConversationApp
//
//  Created by HOME on 29/11/2025.
//

import SwiftUI
import Conversation
import ConversationUI

// MARK: - Composition Root
// Analogous to SceneDelegate in the Feed App.
// This is the only place in the app that creates concrete service objects
// and passes them into the Composer.
//
// @StateObject wraps the initialiser in a lazy @autoclosure that SwiftUI
// always evaluates on the main actor — so @MainActor-isolated Composer
// methods are called safely without a manual Task or DispatchQueue.
// A missing / empty API key surfaces through the normal error path:
// OpenAIService.sendMessage throws .missingAPIKey → Presenter → error state.

@main
struct ConversationAppApp: App {
    @StateObject private var viewModel = ConversationUIComposer.conversationComposedWith(
        aiService: RemoteChatLoader(
            url: URL(string: "https://api.openai.com/v1/chat/completions")!,
            apiKey: AppSecrets.openAIAPIKey ?? "",
            client: URLSessionHTTPClient(timeoutInterval: 60)
        ),
        speechRecognizer: SpeechRecognizer(),
        speechSynthesizer: SpeechSynthesizer()
    )

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: viewModel)
        }
    }
}
