import Foundation

public protocol ChessGameEngine {
    var sideToMove: EngineColor { get }
    var currentFEN: String { get }
    var kingInCheckColor: EngineColor? { get }
    var gameState: EngineGameState { get }
    var currentMoveId: String? { get }
    var boardPGNElements: [PGNAnnotation] { get }

    func forceTurn(to color: EngineColor)
    func piece(at squareString: String) -> EnginePiece?
    func legalMoves(for squareString: String) -> [String]
    func legalMoveCount() -> Int
    func move(from source: String, to target: String, promotion: String?) -> Bool
    func wouldMoveResultInCheckmate(from source: String, to target: String, promotion: String?) -> Bool
    func isEnPassantCapture(from source: String, to target: String) -> Bool
    func undo() -> Bool
    func resetToStart()
    func jump(to moveId: String)
}