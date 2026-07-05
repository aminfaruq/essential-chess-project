//
//  BoardGeometry.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import Foundation
import CoreGraphics

/// A pure mathematical model that handles the spatial calculations and orientations of a chess board.
public struct BoardGeometry {
    
    /// The physical boundaries of the board view.
    public let bounds: CGSize
    
    /// Indicates if the board is flipped (Black at the bottom).
    public let isFlipped: Bool
    
    public init(bounds: CGSize, isFlipped: Bool) {
        self.bounds = bounds
        self.isFlipped = isFlipped
    }
    
    /// The ranks (rows) of the board, ordered from top to bottom.
    public var ranks: [Int] {
        return isFlipped ? [1, 2, 3, 4, 5, 6, 7, 8] : [8, 7, 6, 5, 4, 3, 2, 1]
    }
    
    /// The files (columns) of the board, ordered from left to right.
    public var files: [String] {
        return isFlipped ? ["h", "g", "f", "e", "d", "c", "b", "a"] : ["a", "b", "c", "d", "e", "f", "g", "h"]
    }
    
    /// The calculated width of a single square.
    public var squareWidth: CGFloat {
        return bounds.width / 8.0
    }
    
    /// The calculated height of a single square.
    public var squareHeight: CGFloat {
        return bounds.height / 8.0
    }
    
    /// Converts a physical point within the bounds to its corresponding algebraic square notation.
    /// - Parameter point: The 2D coordinate inside the board.
    /// - Returns: The algebraic notation (e.g., "e4") if the point is within bounds, otherwise nil.
    public func squareString(at point: CGPoint) -> String? {
        let fileIndex = Int(point.x / squareWidth)
        let rankIndex = Int(point.y / squareHeight)
        
        guard fileIndex >= 0 && fileIndex < 8 && rankIndex >= 0 && rankIndex < 8 else {
            return nil
        }
        
        return "\(files[fileIndex])\(ranks[rankIndex])"
    }
}
