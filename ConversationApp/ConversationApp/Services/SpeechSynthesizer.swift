import AVFoundation
import Conversation

class SpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate, SpeechSynthesizing {
    private let synthesizer = AVSpeechSynthesizer()
    var onComplete: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    func speak(_ text: String) {
        do {
            try AudioSessionManager.shared.activateForPlayback()
        } catch {
            print("Failed to set audio session for playback: \(error)")
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        AudioSessionManager.shared.deactivate()
        DispatchQueue.main.async { [weak self] in
            self?.onComplete?()
        }
    }
}
