import SwiftUI
import AIAppFeature

struct ControlsView: View {
    @ObservedObject var viewModel: ConversationViewModel
    @State private var typedText: String = ""
    
    var body: some View {
        VStack {
            transcriptCard
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                if viewModel.state == .processing {
                    Button("Cancel") { viewModel.cancelPendingRequest() }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Cancel request")
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                if viewModel.state == .listening {
                    viewModel.stopRecording()
                } else {
                    viewModel.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.state == .listening ? Color.red : Color.accentColor)
                        .frame(width: 80, height: 80)
                        .shadow(radius: 5)
                    
                    Image(systemName: viewModel.state == .listening ? "stop.fill" : "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.state == .processing || viewModel.state == .speaking)
            .opacity(viewModel.state == .processing || viewModel.state == .speaking ? 0.5 : 1.0)
            .accessibilityLabel(viewModel.state == .listening ? "Stop recording" : "Start recording")
            .accessibilityHint("Double tap to toggle microphone")
            
            HStack(spacing: 8) {
                if viewModel.state == .processing {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(viewModel.state.statusText)
                    .font(.headline)
            }
            .padding(.top, 8)

            HStack(spacing: 10) {
                TextField("Type a message…", text: $typedText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...3)

                Button("Send") {
                    let text = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !text.isEmpty else { return }
                    typedText = ""
                    viewModel.sendMessage(text)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.state == .processing || viewModel.state == .speaking || typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.top, 10)
        }
        .padding()
    }

    private var transcriptCard: some View {
        Group {
            if viewModel.state == .listening {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Listening")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(viewModel.currentTranscript.isEmpty ? "…" : viewModel.currentTranscript)
                        .font(.callout)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            } else {
                Spacer().frame(height: 0)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 0)
    }
}
