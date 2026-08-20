import UIKit
internal import SnapKit

/// A base view that contains the shared rendering, interaction, and feedback
/// machinery for interactive chess boards. Puzzle and Analysis boards extend it
/// and only implement their own move-handling logic.
public class ChessBoardView: UIView {

    // MARK: - Internal Dependencies & State

    var engine: ChessGameEngine?
    var userColor: EngineColor = .white
    var selectedSquareString: String?

    /// Board feedback service injected at init. The `var` is required so the
    /// settable `BoardFeedback` requirements can be mutated; it is never replaced.
    var feedback: BoardFeedback
    let engineFactory: (String) -> ChessGameEngine

    // MARK: - Interaction

    let interactionHandler = BoardInteractionHandler()

    // MARK: - View State

    public var isBoardLocked = true

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

    // MARK: - Initialization

    public override init(frame: CGRect) {
        self.feedback = SystemBoardFeedback()
        self.engineFactory = { ChessEngine(fen: $0) }
        super.init(frame: frame)
        setupContainers()
        setupBoardGrid()
        setupGestures()
    }

    /// Injects the board feedback service and engine factory so tests can supply
    /// spies/doubles. Both are immutable after init.
    init(frame: CGRect = .zero, feedback: BoardFeedback, engineFactory: @escaping (String) -> ChessGameEngine) {
        self.feedback = feedback
        self.engineFactory = engineFactory
        super.init(frame: frame)
        setupContainers()
        setupBoardGrid()
        setupGestures()
    }

    public required init?(coder: NSCoder) {
        self.feedback = SystemBoardFeedback()
        self.engineFactory = { ChessEngine(fen: $0) }
        super.init(coder: coder)
        setupContainers()
        setupBoardGrid()
        setupGestures()
    }

    // MARK: - Theme customization

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

    public func setHapticEnabled(_ isEnabled: Bool) {
        feedback.isHapticEnabled = isEnabled
    }

    public func setSoundEnabled(_ isEnabled: Bool) {
        feedback.isSoundEnabled = isEnabled
    }

    public func setHighlightColor(_ baseColor: UIColor, alpha: CGFloat = 0.35) {
        self.highlightColor = baseColor.withAlphaComponent(alpha)
        highlightViews.values.forEach { $0.backgroundColor = self.highlightColor }
    }

    public func clearSolutionArrow() {
        solutionArrowContainer?.removeFromSuperview()
        solutionArrowContainer = nil
    }

    // MARK: - Interaction Hooks (overridable)

    /// Whether the board currently rejects interaction. Defaults to `isBoardLocked`.
    var interactionLocked: Bool { isBoardLocked }

    /// Whether tapping an own-side piece while another piece is selected switches
    /// the selection (Analysis) instead of attempting the move (Puzzle).
    var switchesSelectionOnOwnPieceTap: Bool { false }

    /// Called when an interaction produces a move. Subclasses implement their own
    /// move handling (puzzle validation, analysis playback, ...).
    func handleMove(from source: String, to target: String, promotionChar: String? = nil) {}

    /// Alternative piece image used by a subclass instead of the theme piece files.
    /// Returning nil falls back to the default `UIImage(named:)` lookup.
    func alternativePieceImage(for piece: EnginePiece, at square: String) -> (image: UIImage, inset: CGFloat)? {
        return nil
    }
}