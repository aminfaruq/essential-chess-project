import UIKit
internal import SnapKit

/// A custom, highly interactive chess board view built natively with UIKit.
/// Acts purely as an I/O interactive board for Analysis and Free Play scenarios.
public final class AnalysisChessBoardView: ChessBoardView {

    // MARK: - Callbacks
    public var onUserMoved: ((String) -> Void)?
    public var onGameStateChanged: ((String) -> Void)?
    public var onStateChanged: (([PGNAnnotation], String?) -> Void)?

    public var currentFen: String? {
        return engine?.currentFEN
    }

    override var switchesSelectionOnOwnPieceTap: Bool { true }

    override func handleMove(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        processUserMove(from: sourceStr, to: targetStr, promotionChar: promotionChar)
    }

    // MARK: - Public API
    public func setPosition(fen: String, orientation: EngineColor = .white) {
        self.engine = engineFactory(fen)

        let needsGridSetup = (self.userColor != orientation) || squareViews.isEmpty
        self.userColor = orientation

        if needsGridSetup {
            setupBoardGrid()
        }

        self.selectedSquareString = nil
        self.isBoardLocked = false

        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()
        broadcastState()
    }

    public func undoLastMove() {
        guard let engine = engine, engine.undo() else { return }

        self.selectedSquareString = nil
        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()
        broadcastState()
    }

    public func resetToStart() {
        guard let engine = engine else { return }
        engine.resetToStart()

        self.selectedSquareString = nil
        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()
        broadcastState()
    }

    public func flipBoard() {
        self.userColor = (self.userColor == .white) ? .black : .white
        setupBoardGrid()

        self.selectedSquareString = nil
        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()
    }

    public func jump(to moveId: String) {
        guard let engine = engine else { return }
        engine.jump(to: moveId)
        self.selectedSquareString = nil
        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()
        broadcastState()

        let fen = self.currentFen ?? ""
        onUserMoved?(fen)
    }

    func broadcastState() {
        guard let engine = engine else { return }
        onStateChanged?(engine.boardPGNElements, engine.currentMoveId)
    }
}