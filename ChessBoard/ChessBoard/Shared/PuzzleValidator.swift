//
//  PuzzleValidator.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

public final class PuzzleValidator {
    private let expectedMoves: [String]
    
    /// The index of the next expected move in the sequence.
    public private(set) var currentIndex: Int = 0
    
    /// Returns true if all expected moves have been successfully validated.
    public var isCompleted: Bool {
        return currentIndex >= expectedMoves.count
    }
    
    public init(expectedMoves: [String]) {
        self.expectedMoves = expectedMoves
    }
    
    /// Validates an attempted move against the expected sequence.
    /// - Parameter move: The UCI string of the attempted move (e.g., "e2e4").
    /// - Returns: True if the move matches the expected sequence, advancing the index. False otherwise.
    public func validate(move: String) -> Bool {
        guard !isCompleted else { return false }
        
        let expectedMove = expectedMoves[currentIndex]
        
        // Use hasPrefix to handle promotion moves where the expected move might be "e7e8q"
        // and the user move might just be evaluated as "e7e8" initially.
        if expectedMove.hasPrefix(move) {
            currentIndex += 1
            return true
        }
        
        return false
    }
    
    /// Retrieves the next expected move and advances the sequence (used for the computer's automated turn).
    /// - Returns: The UCI string of the move, or nil if completed.
    public func consumeNextMove() -> String? {
        guard !isCompleted else { return nil }
        let move = expectedMoves[currentIndex]
        currentIndex += 1
        return move
    }
    
    /// Retrieves the next expected move without advancing the sequence (used for hinting).
    /// - Returns: The UCI string of the move, or nil if completed.
    public func peekNextMove() -> String? {
        guard !isCompleted else { return nil }
        return expectedMoves[currentIndex]
    }
}
