import UIKit
internal import SnapKit

/// A custom, highly interactive chess board view built natively with UIKit.
/// Acts purely as a UI Orchestrator, delegating business logic to the Domain layer.
public final class PuzzleChessBoardView: UIView {
    
    // MARK: - Callbacks
    public var onPuzzleCompleted: (() -> Void)?
    public var onPuzzleWrong: (() -> Void)?
    public var onPuzzleReady: ((String) -> Void)?
    
    // MARK: - Internal Dependencies & State
    var userColor: EngineColor = .white
    
    // MARK: - Internal Dependencies & State (Accessible by Extensions)
    var engine: ChessEngine?
    var puzzleValidator: PuzzleValidator?
    let interactionHandler = BoardInteractionHandler()
    
    public enum PuzzleMode {
        case standard
        case learnThePieces
    }
    
    var puzzleMode: PuzzleMode = .standard
    var isPuzzleCompleted = false
    var isBoardLocked = true
    var selectedSquareString: String?
    
    var squareViews: [String: UIView] = [:]
    var pieceImageViews: [String: UIImageView] = [:]
    var highlightViews: [String: UIView] = [:]
    var checkHighlightViews: [String: UIView] = [:]
    var legalMoveHintViews: [UIView] = []
    
    var solutionArrowContainer: UIView?

    
    var ghostPieceView: UIImageView?
    var dragStartOriginalCenter: CGPoint = .zero
    
    // MARK: - Theme & Geometry
    var lightSquareColor = UIColor(red: 0.94, green: 0.85, blue: 0.71, alpha: 1.0)
    var darkSquareColor = UIColor(red: 0.71, green: 0.53, blue: 0.39, alpha: 1.0)
    var highlightColor = UIColor.systemYellow.withAlphaComponent(0.35)
    var currentPieceTheme: String = "default"
    
    let boardContainer = UIView()
    let overlayView = UIView()
    
    var geometry: BoardGeometry {
        // STATIC orientation: The board is flipped ONLY if the user is playing Black.
        let flipped = userColor == .black
        let currentSize = boardContainer.bounds.isEmpty ? bounds.size : boardContainer.bounds.size
        return BoardGeometry(bounds: currentSize, isFlipped: flipped)
    }
    
    public var userColorName: String {
        return userColor == .black ? "Black" : "White"
    }
    
    // MARK: - Initialization
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupContainers()
        setupBoardGrid()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContainers()
        setupBoardGrid()
        setupGestures()
    }
    
    // MARK: - Public API
    public func startPuzzle(fen: String, moves: [String]) {
        self.engine = ChessEngine(fen: fen)
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
        self.engine = ChessEngine(fen: fen)
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
    
    public func setPieceTheme(_ themePrefix: String) {
        self.currentPieceTheme = themePrefix
        renderPieces()
    }
    
    public func setBoardTheme(light: UIColor, dark: UIColor) {
        self.lightSquareColor = light
        self.darkSquareColor = dark
        setupBoardGrid()
        renderPieces()
    }
    
    /// Enables or disables haptic feedback for the chess board interactions.
    public func setHapticEnabled(_ isEnabled: Bool) {
        HapticManager.shared.isEnabled = isEnabled
    }
    
    /// Enables or disables sound effects for the chess board.
    public func setSoundEnabled(_ isEnabled: Bool) {
        SoundManager.shared.isEnabled = isEnabled
    }
    
    public func setHighlightColor(_ baseColor: UIColor, alpha: CGFloat = 0.35) {
        self.highlightColor = baseColor.withAlphaComponent(alpha)
        highlightViews.values.forEach { $0.backgroundColor = self.highlightColor }
    }
    
    public func showHint() {
        guard let expectedMove = puzzleValidator?.peekNextMove(), !isPuzzleCompleted else { return }
//        clearHighlights()
        if let view = squareViews[String(expectedMove.prefix(2))] {
            view.layer.borderWidth = 4
            view.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.8).cgColor
        }
    }
    
    public func showSolution() {
        guard let expectedMove = puzzleValidator?.peekNextMove(), !isPuzzleCompleted else { return }
        let sourceStr = String(expectedMove.prefix(2))
        let targetStr = String(expectedMove.dropFirst(2).prefix(2))
        drawGreenSolutionArrow(from: sourceStr, to: targetStr)
    }
}
