//
//  SoundManager.swift
//  NativeChessBoard
//

import AVFoundation
import Foundation

/// Manages sound effects for the NativeChessBoard library.
@MainActor
final class SoundManager {
    // Resolves the correct bundle for loading audio resources whether this code
    // is part of an app target or a Swift Package.
    private static var resourceBundle: Bundle = {
        // Prefer Swift Package resources when available
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        // Try the bundle where this class is defined
        let classBundle = Bundle(for: SoundManager.self)
        // If sounds are embedded in a dedicated resource bundle (e.g., NativeChessBoardResources.bundle),
        // try to locate it next to the class bundle. Adjust the name if your resource bundle differs.
        if let url = classBundle.url(forResource: "NativeChessBoardResources", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        // Fallbacks
        return classBundle
        #endif
    }()
    
    static let shared = SoundManager()
    
    /// Determines whether sound effects are allowed to play.
    /// Controlled by the host application.
    var isEnabled: Bool = true
    
#if DEBUG
    /// Test hook to observe triggered sounds
    var onSoundTriggered: ((String) -> Void)?
#endif
    
    private var movePlayer: AVAudioPlayer?
    private var capturePlayer: AVAudioPlayer?
    private var errorPlayer: AVAudioPlayer?
    private var victoryPlayer: AVAudioPlayer?
    
    private init() {
        // Preload sounds
        movePlayer = createPlayer(for: "Move", extension: "mp3")
        capturePlayer = createPlayer(for: "Capture", extension: "mp3")
        errorPlayer = createPlayer(for: "Error", extension: "mp3")
        victoryPlayer = createPlayer(for: "Victory", extension: "mp3")
    }
    
    private func createPlayer(for resource: String, extension ext: String) -> AVAudioPlayer? {
        let bundle = SoundManager.resourceBundle
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
    
    /// Plays the normal move sound.
    func playMove() {
        guard isEnabled else { return }
        movePlayer?.currentTime = 0
        movePlayer?.play()
#if DEBUG
        onSoundTriggered?("playMove")
#endif
    }
    
    /// Plays the capture sound.
    func playCapture() {
        guard isEnabled else { return }
        capturePlayer?.currentTime = 0
        capturePlayer?.play()
#if DEBUG
        onSoundTriggered?("playCapture")
#endif
    }
    
    /// Plays the illegal move / error sound.
    func playError() {
        guard isEnabled else { return }
        errorPlayer?.currentTime = 0
        errorPlayer?.play()
#if DEBUG
        onSoundTriggered?("playError")
#endif
    }
    
    /// Plays the victory / puzzle solved sound.
    func playVictory() {
        guard isEnabled else { return }
        victoryPlayer?.currentTime = 0
        victoryPlayer?.play()
#if DEBUG
        onSoundTriggered?("playVictory")
#endif
    }
}
