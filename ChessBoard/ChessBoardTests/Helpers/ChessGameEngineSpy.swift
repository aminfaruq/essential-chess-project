import Foundation
@testable import ChessBoard

/// A configurable `ChessGameEngine` double that records every received message.
@MainActor
final class ChessGameEngineSpy: ChessGameEngine {

    enum ReceivedMessage: Equatable {
        case forceTurn(EngineColor)
        case piece(String)
        case legalMoves(String)
        case legalMoveCount
        case move(String, String, String?)
        case wouldMoveResultInCheckmate(String, String, String?)
        case isEnPassantCapture(String, String)
        case undo
        case resetToStart
        case jump(String)
    }

    private(set) var receivedMessages = [ReceivedMessage]()

    // MARK: - Configurable Stubs

    var stubbedSideToMove: EngineColor = .white
    var stubbedCurrentFEN: String = ""
    var stubbedKingInCheckColor: EngineColor?
    var stubbedGameState: EngineGameState = .inProgress
    var stubbedCurrentMoveId: String?
    var stubbedBoardPGNElements: [PGNAnnotation] = []
    var stubbedPieces: [String: EnginePiece] = [:]
    var stubbedLegalMoves: [String: [String]] = [:]
    var stubbedLegalMoveCount: Int = 0
    var stubbedMoveReturn: Bool = true
    var stubbedWouldMoveResultInCheckmateReturn: Bool = false
    var stubbedIsEnPassantCaptureReturn: Bool = false
    var stubbedUndoReturn: Bool = true

    func stubbedPiece(at square: String, kind: EnginePieceKind = .pawn, color: EngineColor = .white) {
        stubbedPieces[square] = EnginePiece(kind: kind, color: color)
    }

    // MARK: - Protocol Conformance

    var sideToMove: EngineColor { stubbedSideToMove }

    var currentFEN: String { stubbedCurrentFEN }

    var kingInCheckColor: EngineColor? { stubbedKingInCheckColor }

    var gameState: EngineGameState { stubbedGameState }

    var currentMoveId: String? { stubbedCurrentMoveId }

    var boardPGNElements: [PGNAnnotation] { stubbedBoardPGNElements }

    func forceTurn(to color: EngineColor) {
        receivedMessages.append(.forceTurn(color))
    }

    func piece(at squareString: String) -> EnginePiece? {
        receivedMessages.append(.piece(squareString))
        return stubbedPieces[squareString]
    }

    func legalMoves(for squareString: String) -> [String] {
        receivedMessages.append(.legalMoves(squareString))
        return stubbedLegalMoves[squareString] ?? []
    }

    func legalMoveCount() -> Int {
        receivedMessages.append(.legalMoveCount)
        return stubbedLegalMoveCount
    }

    func move(from source: String, to target: String, promotion: String?) -> Bool {
        receivedMessages.append(.move(source, target, promotion))
        return stubbedMoveReturn
    }

    func wouldMoveResultInCheckmate(from source: String, to target: String, promotion: String?) -> Bool {
        receivedMessages.append(.wouldMoveResultInCheckmate(source, target, promotion))
        return stubbedWouldMoveResultInCheckmateReturn
    }

    func isEnPassantCapture(from source: String, to target: String) -> Bool {
        receivedMessages.append(.isEnPassantCapture(source, target))
        return stubbedIsEnPassantCaptureReturn
    }

    func undo() -> Bool {
        receivedMessages.append(.undo)
        return stubbedUndoReturn
    }

    func resetToStart() {
        receivedMessages.append(.resetToStart)
    }

    func jump(to moveId: String) {
        receivedMessages.append(.jump(moveId))
    }
}