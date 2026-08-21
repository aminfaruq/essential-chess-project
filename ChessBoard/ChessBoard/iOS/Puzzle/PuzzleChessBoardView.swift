import UIKit

/// A custom, highly interactive chess board view built natively with UIKit.
/// Acts purely as a UI Orchestrator, delegating business logic to the Domain layer.
public final class PuzzleChessBoardView: ChessBoardView {

    // MARK: - Callbacks
    public var onPuzzleCompleted: (() -> Void)?
    public var onPuzzleWrong: (() -> Void)?
    public var onPuzzleReady: ((String) -> Void)?

    public enum PuzzleMode {
        case standard
        case learnThePieces
    }

    var puzzleMode: PuzzleMode = .standard
    var isPuzzleCompleted = false
    var puzzleValidator: PuzzleValidator?

    override var interactionLocked: Bool { isBoardLocked || isPuzzleCompleted }

    override func handleMove(from sourceStr: String, to targetStr: String, promotionChar: String? = nil) {
        switch puzzleMode {
        case .standard:
            processUserMove(from: sourceStr, to: targetStr, promotionChar: promotionChar)
        case .learnThePieces:
            processUserMoveForLearnPieces(from: sourceStr, to: targetStr, promotionChar: promotionChar)
        }
    }

    override func alternativePieceImage(for piece: EnginePiece, at square: String) -> (image: UIImage, inset: CGFloat)? {
        guard puzzleMode == .learnThePieces, piece.color != userColor,
              let image = UIImage(systemName: "star.fill")?.withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
        else { return nil }
        return (image, 10)
    }

    // MARK: - Public API
    public func startPuzzle(fen: String, moves: [String]) {
        self.engine = engineFactory(fen)
        self.puzzleValidator = PuzzleValidator(expectedMoves: moves)

        // The user plays the opposite of the starting FEN's turn.
        self.userColor = self.engine?.sideToMove == .white ? .black : .white

        setupBoardGrid()

        self.puzzleMode = .standard
        self.isPuzzleCompleted = false
        self.selectedSquareString = nil
        self.isBoardLocked = true

        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()

        onPuzzleReady?(self.userColorName)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.makeOpponentMove()
        }
    }

    public func startLearnThePiecesPuzzle(fen: String) {
        self.engine = engineFactory(fen)
        self.puzzleValidator = PuzzleValidator(expectedMoves: [])

        // In Learn The Pieces, there is no initial opponent move.
        // The user plays the color that is currently indicated by the FEN.
        self.userColor = self.engine?.sideToMove ?? .white

        setupBoardGrid()

        self.puzzleMode = .learnThePieces
        self.isPuzzleCompleted = false
        self.selectedSquareString = nil
        self.isBoardLocked = false // User can move immediately

        cleanupGhost()
        clearSolutionArrow()
        clearLegalMoveHints()
        clearHighlights()
        renderPieces()

        onPuzzleReady?(self.userColorName)
    }

    public func showHint() {
        guard let expectedMove = puzzleValidator?.peekNextMove(), !isPuzzleCompleted else { return }
        if let view = squareViews[String(expectedMove.prefix(2))] {
            view.layer.borderWidth = 4
            view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        }
    }

    public func showSolution() {
        guard let expectedMove = puzzleValidator?.peekNextMove(), !isPuzzleCompleted else { return }
        let sourceStr = String(expectedMove.prefix(2))
        let targetStr = String(expectedMove.dropFirst(2).prefix(2))
        drawArrow(from: sourceStr, to: targetStr, color: UIColor.systemGreen.withAlphaComponent(0.8), isPersistent: true)
    }
}