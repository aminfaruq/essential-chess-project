import Foundation

@MainActor
public final class SystemBoardFeedback: BoardFeedback {
    private let hapticFeedback: HapticFeedback
    private let soundFeedback: SoundFeedback

    public var isHapticEnabled: Bool {
        get { hapticFeedback.isEnabled }
        set { hapticFeedback.isEnabled = newValue }
    }

    public var isSoundEnabled: Bool {
        get { soundFeedback.isEnabled }
        set { soundFeedback.isEnabled = newValue }
    }

    public init() {
        self.hapticFeedback = HapticFeedback()
        self.soundFeedback = SoundFeedback()
    }

    init(hapticFeedback: HapticFeedback, soundFeedback: SoundFeedback) {
        self.hapticFeedback = hapticFeedback
        self.soundFeedback = soundFeedback
    }

    public func piecePickUp() { hapticFeedback.piecePickUp() }

    public func moveIllegal() {
        hapticFeedback.moveIllegal()
        soundFeedback.playError()
    }

    public func moveCapture() {
        hapticFeedback.moveCapture()
        soundFeedback.playCapture()
    }

    public func playMove() { soundFeedback.playMove() }

    public func playCapture() { soundFeedback.playCapture() }

    public func playError() { soundFeedback.playError() }

    /// Victory plays the rigid impact haptic (previously `moveCapture`) together
    /// with the victory sound, matching the original checkmate/win feedback.
    public func playVictory() {
        hapticFeedback.moveCapture()
        soundFeedback.playVictory()
    }

    public func playCheck() { soundFeedback.playCheck() }
}