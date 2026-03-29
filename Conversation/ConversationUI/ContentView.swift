import SwiftUI
import Conversation

/// Main SwiftUI shell for the voice chat experience. Lives in `ConversationUI` so the core
/// `Conversation` module stays free of SwiftUI (see Essential Feed’s Feed vs EssentialFeediOS split).
public struct ContentView: View {
    @ObservedObject private var viewModel: ConversationViewModel

    public init(viewModel: ConversationViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    public var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ChatView(viewModel: viewModel)
                Divider()
                ControlsView(viewModel: viewModel)
            }
        }
        .onAppear { viewModel.requestPermissions() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Voice Chat")
                    .font(.headline)
                Text(viewModel.state.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Reset") { viewModel.resetConversation() }
                .buttonStyle(.bordered)
                .disabled(viewModel.messages.isEmpty && viewModel.state == .idle)
                .accessibilityLabel("Reset conversation")
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }
}
