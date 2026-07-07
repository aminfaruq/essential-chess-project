import UIKit
internal import ChessKit
internal import SnapKit

/// A custom, highly interactive chess board view built natively with UIKit.
/// Acts purely as an I/O interactive board for Analysis and Free Play scenarios.
public final class AnalysisChessBoardView: UIView {
    
    // MARK: - Callbacks
    public var onUserMoved: ((String) -> Void)?
    public var onGameStateChanged: ((String) -> Void)?
    public var onStateChanged: (([PGNAnnotation], String?) -> Void)?
    
    // MARK: - Internal Dependencies & State
    var userColor: EngineColor = .white
    
    // MARK: - Internal Dependencies & State (Accessible by Extensions)
    var engine: ChessEngine?
    let interactionHandler = BoardInteractionHandler()
    
    public var isBoardLocked = true
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
        let flipped = userColor == .black
        let currentSize = boardContainer.bounds.isEmpty ? bounds.size : boardContainer.bounds.size
        return BoardGeometry(bounds: currentSize, isFlipped: flipped)
    }
    
    public var userColorName: String {
        return userColor == .black ? "Black" : "White"
    }
    
    public var currentFen: String? {
        return engine?.currentFEN
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
    public func setPosition(fen: String, orientation: EngineColor = .white) {
        self.engine = ChessEngine(fen: fen)
        
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
