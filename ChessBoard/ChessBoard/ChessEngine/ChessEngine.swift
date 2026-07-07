//
//  ChessEngine.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//
import Foundation
internal import ChessKit

// MARK: - Domain Primitives

/// Represents the color of a chess piece or player turn.
public enum EngineColor: Equatable {
    case white
    case black
}

/// Represents the type of a chess piece.
public enum EnginePieceKind: Equatable {
    case pawn, knight, bishop, rook, queen, king
}

/// A simplified representation of a chess piece to be consumed by the View layer.
public struct EnginePiece: Equatable {
    public let kind: EnginePieceKind
    public let color: EngineColor
    
    public init(kind: EnginePieceKind, color: EngineColor) {
        self.kind = kind
        self.color = color
    }
}

// MARK: - Core Engine Adapter

/// An adapter class that encapsulates the third-party chess logic (ChessKit),
/// providing a clean, decoupled interface for the View layer.
public final class ChessEngine {
    
    private var game: Game
    private var currentIndex: MoveTree.Index
    private var indexMap: [String: MoveTree.Index] = [:]
    private var indexToIdMap: [MoveTree.Index: String] = [:]
    
    /// Indicates which color's turn it is to move.
    public var sideToMove: EngineColor {
        guard let position = game.positions[currentIndex] else { return .white }
        return position.sideToMove == .white ? .white : .black
    }
    
    /// Gets the current FEN string of the board.
    public var currentFEN: String {
        guard let position = game.positions[currentIndex] else { return "" }
        return position.fen
    }
    
    /// Forces the turn to a specific color by modifying the current FEN.
    public func forceTurn(to color: EngineColor) {
        let fen = currentFEN
        var tokens = fen.components(separatedBy: " ")
        guard tokens.count >= 2 else { return }
        tokens[1] = color == .white ? "w" : "b"
        let newFen = tokens.joined(separator: " ")
        if let newPos = Position(fen: newFen) {
            self.game = Game(startingWith: newPos)
            self.currentIndex = self.game.startingIndex
            self.indexMap = [:]
            self.indexToIdMap = [:]
        }
    }
    
    /// Returns the color of the king currently under check, or nil if no king is in check.
    public var kingInCheckColor: EngineColor? {
        guard let position = game.positions[currentIndex] else { return nil }
        
        let fenTokens = position.fen.components(separatedBy: " ")
        guard fenTokens.count >= 2 else { return nil }
        
        var newTokens = fenTokens
        let side = fenTokens[1]
        
        if side == "w" { newTokens[1] = "b" }
        else if side == "b" { newTokens[1] = "w" }
        else { return nil }
        
        let dummyFen = newTokens.joined(separator: " ")
        guard let dummyPos = Position(fen: dummyFen) else { return nil }
        
        let dummyBoard = Board(position: dummyPos)
        switch dummyBoard.state {
        case .check(let color), .checkmate(let color):
            return color == .white ? .white : .black
        default:
            return nil
        }
    }
    
    /// Initializes the engine with a specific Forsyth-Edwards Notation (FEN) string.
    /// - Parameter fen: The starting position.
    public init(fen: String) {
        if let position = Position(fen: fen) {
            self.game = Game(startingWith: position)
        } else {
            self.game = Game() // Fallback
        }
        self.currentIndex = self.game.startingIndex
    }
    
    /// Retrieves a simplified piece representation at a given algebraic square.
    /// - Parameter squareString: Algebraic notation (e.g., "e2").
    /// - Returns: An `EnginePiece` if a piece exists, otherwise nil.
    public func piece(at squareString: String) -> EnginePiece? {
        guard let position = game.positions[currentIndex],
              let piece = position.piece(at: Square(squareString)) else { return nil }
        
        let kind: EnginePieceKind
        switch piece.kind {
        case .pawn: kind = .pawn
        case .knight: kind = .knight
        case .bishop: kind = .bishop
        case .rook: kind = .rook
        case .queen: kind = .queen
        case .king: kind = .king
        }
        
        let color: EngineColor = piece.color == .white ? .white : .black
        return EnginePiece(kind: kind, color: color)
    }
    
    /// Calculates all physically legal destination squares for a piece at a given square.
    /// - Parameter squareString: The starting square notation.
    /// - Returns: An array of algebraic notations for legal destinations.
    public func legalMoves(for squareString: String) -> [String] {
        guard let position = game.positions[currentIndex] else { return [] }
        let board = Board(position: position)
        var legalSquares = board.legalMoves(forPieceAt: Square(squareString)).map { $0.notation }
        
        if let epTarget = validEnPassantTarget(for: squareString) {
            legalSquares.append(epTarget)
        }
        
        return legalSquares
    }
    
    /// Counts total legal moves available for the side to move in the current position.
    /// - Returns: Total number of legal moves across all pieces, or -1 if position is invalid.
    public func legalMoveCount() -> Int {
        guard let position = game.positions[currentIndex] else { return -1 }
        let board = Board(position: position)

        var total = 0
        for square in Square.allCases {
            if let piece = position.piece(at: square),
               piece.color == position.sideToMove {
                total += board.legalMoves(forPieceAt: square).count
            }
        }
        return total
    }
    
    /// Attempts to execute a move on the board.
    /// - Parameters:
    ///   - source: The starting square notation.
    ///   - target: The destination square notation.
    ///   - promotion: An optional single character indicating promotion (e.g., "q").
    /// - Returns: True if the move was successfully executed.
    public func move(from source: String, to target: String, promotion: String? = nil) -> Bool {
        guard let position = game.positions[currentIndex] else { return false }
        
        let startSquare = Square(source)
        let endSquare = Square(target)
        var board = Board(position: position)
        
        if isEnPassantCapture(from: source, to: target), validEnPassantTarget(for: source) == target {
            // ChessKit's Game.make drops epTarget, so board.canMove might return false.
            // We manually construct and apply the En Passant move.
            let capturedSquareNotation = "\(target.first!)\(source.last!)"
            if let capturedPiece = position.piece(at: Square(capturedSquareNotation)),
               let movingPawn = position.piece(at: Square(source)) {
                
                let epMove = Move(
                    result: .capture(capturedPiece),
                    piece: movingPawn,
                    start: Square(source),
                    end: Square(target)
                )
                let newIndex = game.make(move: epMove, from: currentIndex)
                self.currentIndex = newIndex
                return true
            }
        }
        
        if !board.canMove(pieceAt: startSquare, to: endSquare) {
            return false
        }
        
        if var validMove = board.move(pieceAt: startSquare, to: endSquare) {
            if let promo = promotion, promo.count == 1 {
                let kind: Piece.Kind
                switch promo.lowercased() {
                case "r": kind = .rook
                case "b": kind = .bishop
                case "n": kind = .knight
                default: kind = .queen
                }
                validMove = board.completePromotion(of: validMove, to: kind)
            }
            
            let newIndex = game.make(move: validMove, from: currentIndex)
            self.currentIndex = newIndex
            return true
        }
        return false
    }
    
    /// Checks if a move would result in a checkmate without actually committing the move to the engine.
    /// This is useful for validating alternative puzzle solutions (e.g., multiple mate-in-1s).
    /// - Parameters:
    ///   - source: The starting square notation.
    ///   - target: The destination square notation.
    ///   - promotion: An optional single character indicating promotion (e.g., "q").
    /// - Returns: True if the move is legal and results in a checkmate.
    public func wouldMoveResultInCheckmate(from source: String, to target: String, promotion: String? = nil) -> Bool {
        guard let position = game.positions[currentIndex] else { return false }
        
        let startSquare = Square(source)
        let endSquare = Square(target)
        var board = Board(position: position)
        if isEnPassantCapture(from: source, to: target), validEnPassantTarget(for: source) == target {
            let capturedSquareNotation = "\(target.first!)\(source.last!)"
            if let capturedPiece = position.piece(at: Square(capturedSquareNotation)),
               let movingPawn = position.piece(at: Square(source)) {
                
                let epMove = Move(
                    result: .capture(capturedPiece),
                    piece: movingPawn,
                    start: Square(source),
                    end: Square(target)
                )
                
                var tempGame = game
                let newIndex = tempGame.make(move: epMove, from: currentIndex)
                if let newPosition = tempGame.positions[newIndex] {
                    let tempBoard = Board(position: newPosition)
                    switch tempBoard.state {
                    case .checkmate: return true
                    default: return false
                    }
                }
            }
        }
        
        if !board.canMove(pieceAt: startSquare, to: endSquare) {
            return false
        }
        
        if var validMove = board.move(pieceAt: startSquare, to: endSquare) {
            if let promo = promotion, promo.count == 1 {
                let kind: Piece.Kind
                switch promo.lowercased() {
                case "r": kind = .rook
                case "b": kind = .bishop
                case "n": kind = .knight
                default: kind = .queen
                }
                validMove = board.completePromotion(of: validMove, to: kind)
            }
            
            switch board.state {
            case .checkmate:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Game State Detection
    
    /// Represents the current state of the game.
    public enum GameState: Equatable {
        case inProgress
        case check(EngineColor)
        case checkmate(EngineColor)
        case stalemate
    }
    
    /// Returns the current game state after the last move.
    public var gameState: GameState {
        guard let position = game.positions[currentIndex] else { return .inProgress }
        let board = Board(position: position)
        switch board.state {
        case .checkmate(let color):
            return .checkmate(color == .white ? .white : .black)
        case .check(let color):
            return .check(color == .white ? .white : .black)
        case .draw(let reason) where reason == .stalemate:
            return .stalemate
        case .draw:
            return .stalemate // All draw types treated as stalemate for UI purposes
        default:
            return .inProgress
        }
    }
    
    /// Checks if a pawn move from source to target is an en passant capture.
    /// An en passant occurs when a pawn moves diagonally but the target square is empty.
    /// - Parameters:
    ///   - source: The starting square notation.
    ///   - target: The destination square notation.
    /// - Returns: True if this is an en passant capture.
    public func isEnPassantCapture(from source: String, to target: String) -> Bool {
        guard let sourcePiece = piece(at: source), sourcePiece.kind == .pawn else { return false }
        
        // En passant: pawn moves to a different file but the target square is empty
        let sourceFile = source.first
        let targetFile = target.first
        return sourceFile != targetFile && self.piece(at: target) == nil
    }
    
    /// Undoes the last move if possible.
    /// - Returns: True if a move was successfully undone.
    public func undo() -> Bool {
        if currentIndex == game.startingIndex {
            return false
        }
        
        let prevIndex = game.moves.index(before: currentIndex)
        if prevIndex == currentIndex {
            return false
        }
        
        if game.positions[prevIndex] != nil {
            self.currentIndex = prevIndex
            return true
        }
        
        
        return false
    }
    
    /// Resets the engine back to the starting position.
    public func resetToStart() {
        self.currentIndex = game.startingIndex
    }
    
    /// Jumps to a specific move index in the tree using a string ID.
    public func jump(to moveId: String) {
        if let index = indexMap[moveId], game.positions[index] != nil {
            self.currentIndex = index
        }
    }
    
    /// Exposes the current move identifier.
    public var currentMoveId: String? {
        return indexToIdMap[currentIndex]
    }
    
    /// Exposes the PGN elements without leaking internal ChessKit types.
    public var boardPGNElements: [PGNAnnotation] {
        var newMap: [String: MoveTree.Index] = [:]
        var newReverseMap: [MoveTree.Index: String] = [:]
        var counter = 0
        let elements = game.moves.pgnRepresentation.map { element -> PGNAnnotation in
            switch element {
            case let .whiteNumber(number):
                return .whiteNumber(number)
            case let .blackNumber(number):
                return .blackNumber(number)
            case let .move(move, index):
                let id = "m\(counter)"
                counter += 1
                newMap[id] = index
                newReverseMap[index] = id
                return .move(san: move.san, moveId: id)
            case let .positionAssessment(assessment):
                return .positionAssessment(assessment.rawValue)
            case .variationStart:
                return .variationStart
            case .variationEnd:
                return .variationEnd
            }
        }
        self.indexMap = newMap
        self.indexToIdMap = newReverseMap
        return elements
    }
    
    // MARK: - En Passant Manual Detection
    
    /// Manually determines if the pawn at `pawnSquare` has a valid en passant target square.
    /// This is necessary because `ChessKit`'s `Game.make` drops the FEN `epTarget` state on double pawn pushes.
    private func validEnPassantTarget(for pawnSquare: String) -> String? {
        guard let position = game.positions[currentIndex] else { return nil }
        guard let pawn = position.piece(at: Square(pawnSquare)), pawn.kind == .pawn else { return nil }
        
        // Find the last move made to reach currentIndex
        guard let lastMove = game.moves[currentIndex] else {
            return nil
        }
        
        // The last move must be a double pawn push by the opponent
        guard lastMove.piece.kind == .pawn,
              lastMove.piece.color != pawn.color,
              abs(lastMove.start.rank.value - lastMove.end.rank.value) == 2 else {
            return nil
        }
        
        // The opponent's pawn must have landed adjacent to our pawn
        let opponentPawnSquare = lastMove.end
        let ourSquare = Square(pawnSquare)
        
        guard let ourFileAscii = ourSquare.file.rawValue.first?.asciiValue,
              let oppFileAscii = opponentPawnSquare.file.rawValue.first?.asciiValue else {
            return nil
        }
        
        guard ourSquare.rank == opponentPawnSquare.rank,
              abs(Int(ourFileAscii) - Int(oppFileAscii)) == 1 else {
            return nil
        }
        
        // Target is the square exactly behind the opponent's pawn
        let direction = pawn.color == .white ? 1 : -1
        let targetRank = opponentPawnSquare.rank.value + direction
        let targetFile = opponentPawnSquare.file.rawValue
        
        if let fileScalar = UnicodeScalar(targetFile),
           let fileChar = Character(fileScalar) as Character?,
           (1...8).contains(targetRank) {
            return "\(fileChar)\(targetRank)"
        }
        
        return nil
    }
}
