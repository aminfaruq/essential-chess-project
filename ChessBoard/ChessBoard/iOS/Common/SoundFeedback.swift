import AVFoundation
import Foundation

@MainActor
final class SoundFeedback {
    private static var resourceBundle: Bundle = {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let classBundle = Bundle(for: SoundFeedback.self)
        if let url = classBundle.url(forResource: "NativeChessBoardResources", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return classBundle
#endif
    }()
    
    var isEnabled: Bool = true
    
    private var onSoundTriggered: ((String) -> Void)?
    
    private var movePlayer: AVAudioPlayer?
    private var capturePlayer: AVAudioPlayer?
    private var errorPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?
    
    init(onSoundTriggered: ((String) -> Void)? = nil) {
        self.onSoundTriggered = onSoundTriggered
        movePlayer = createPlayer(for: "Move", extension: "mp3")
        capturePlayer = createPlayer(for: "Capture", extension: "mp3")
        errorPlayer = createPlayer(for: "Error", extension: "mp3")
        victoryPlayer = createPlayer(for: "Victory", extension: "mp3")
    }
    
    private func createPlayer(for resource: String, extension ext: String) -> AVAudioPlayer? {
        let bundle = SoundFeedback.resourceBundle
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            print("NativeChessBoard: Could not find sound file \(resource).\(ext)")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("NativeChessBoard: Failed to load sound file \(resource).\(ext) - \(error)")
            return nil
        }
    }
    
    func playMove() {
        guard isEnabled else { return }
        movePlayer?.currentTime = 0
        movePlayer?.play()
        onSoundTriggered?("playMove")
    }
    
    func playCapture() {
        guard isEnabled else { return }
        capturePlayer?.currentTime = 0
        capturePlayer?.play()
        onSoundTriggered?("playCapture")
    }
    
    func playError() {
        guard isEnabled else { return }
        errorPlayer?.currentTime = 0
        errorPlayer?.play()
        onSoundTriggered?("playError")
    }
    
    func playVictory() {
        guard isEnabled else { return }
        victoryPlayer?.currentTime = 0
        victoryPlayer?.play()
        onSoundTriggered?("playVictory")
    }
    
    func playCheck() {
        guard isEnabled else { return }
        capturePlayer?.currentTime = 0
        capturePlayer?.play()
        onSoundTriggered?("playCheck")
    }
}
