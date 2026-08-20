import Foundation
@testable import ChessBoard

/// Records every `BoardFeedback` call triggered by the board views.
@MainActor
final class BoardFeedbackSpy: BoardFeedback {

    enum ReceivedMessage: Equatable {
        case piecePickUp
        case moveIllegal
        case moveCapture
        case playMove
        case playCapture
        case playError
        case playVictory
        case playCheck
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    var isHapticEnabled: Bool = true
    var isSoundEnabled: Bool = true

    func piecePickUp() { receivedMessages.append(.piecePickUp) }

    func moveIllegal() { receivedMessages.append(.moveIllegal) }

    func moveCapture() { receivedMessages.append(.moveCapture) }

    func playMove() { receivedMessages.append(.playMove) }

    func playCapture() { receivedMessages.append(.playCapture) }

    func playError() { receivedMessages.append(.playError) }

    func playVictory() { receivedMessages.append(.playVictory) }

    func playCheck() { receivedMessages.append(.playCheck) }
}