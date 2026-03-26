import SwiftUI
import AIAppFeature

struct ContentView: View {
    @ObservedObject var viewModel: ConversationViewModel

    var body: some View {
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
