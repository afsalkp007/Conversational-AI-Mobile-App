import SwiftUI
import AIAppFeature

struct ChatView: View {
    @ObservedObject var viewModel: ConversationViewModel
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if viewModel.messages.isEmpty {
                        emptyState
                            .padding(.top, 30)
                    }

                    ForEach(viewModel.messages) { message in
                        BubbleView(message: message)
                            .id(message.id)
                    }

                    if viewModel.state == .processing {
                        BubbleView(
                            message: Message(role: .assistant, content: "Thinking…")
                        )
                        .id("thinking")
                        .transition(.opacity)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _ in
                if let lastId = viewModel.messages.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.state) { state in
                if state == .processing {
                    withAnimation {
                        proxy.scrollTo("thinking", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.secondary)
            Text("Tap the microphone and speak.")
                .font(.headline)
            Text("You’ll see your live transcript, then the AI will reply and speak back.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
    }
}
