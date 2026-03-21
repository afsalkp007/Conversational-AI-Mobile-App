import AVFoundation

final class AudioSessionManager {
    static let shared = AudioSessionManager()

    private let session = AVAudioSession.sharedInstance()
    private let queue = DispatchQueue(label: "AudioSessionManager.queue")

    private init() {}

    func activateForRecording() throws {
        try queue.sync {
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.duckOthers, .allowBluetooth, .defaultToSpeaker]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }
    }

    func activateForPlayback() throws {
        try queue.sync {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        }
    }

    func deactivate() {
        queue.async {
            try? self.session.setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}

