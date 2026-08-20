import Foundation

public protocol BoardFeedback {
    var isHapticEnabled: Bool { get set }
    var isSoundEnabled: Bool { get set }

    func piecePickUp()
    func moveIllegal()
    func moveCapture()
    func playMove()
    func playCapture()
    func playError()
    func playVictory()
    func playCheck()
}