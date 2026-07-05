//
//  ChessEngineTests.swift
//  NativeChessBoard
//
//  Created by Amin faruq on 08/06/26.
//

import XCTest
@testable import ChessBoard

@MainActor
final class ChessEngineTests: XCTestCase {
    
    func test_init_withValidFEN_setsUpInitialState() {
        // Given
        let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let sut = makeSUT(fen: startingFEN)
        
        // Then
        XCTAssertEqual(sut.sideToMove, .white)
        
        let e2Piece = sut.piece(at: "e2")
        XCTAssertNotNil(e2Piece)
        XCTAssertEqual(e2Piece?.kind, .pawn)
        XCTAssertEqual(e2Piece?.color, .white)
    }
    
    func test_legalMoves_returnsCorrectSquares() {
        // Given
        let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let sut = makeSUT(fen: startingFEN)
        
        // When
        let moves = sut.legalMoves(for: "e2")
        
        // Then
        XCTAssertTrue(moves.contains("e3"))
        XCTAssertTrue(moves.contains("e4"))
        XCTAssertFalse(moves.contains("e5"))
    }
    
    func test_move_validMove_updatesStateAndReturnsTrue() {
        // Given
        let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let sut = makeSUT(fen: startingFEN)
        
        // When
        let success = sut.move(from: "e2", to: "e4", promotion: nil)
        
        // Then
        XCTAssertTrue(success)
        XCTAssertNil(sut.piece(at: "e2")) // The square should be empty now
        XCTAssertNotNil(sut.piece(at: "e4")) // The piece should have moved here
        XCTAssertEqual(sut.sideToMove, .black) // Turn changes
    }
    
    func test_getKingInCheckColor_returnsNilWhenNoCheck() {
        // Given
        let startingFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        let sut = makeSUT(fen: startingFEN)
        
        // Then
        XCTAssertNil(sut.kingInCheckColor)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(fen: String, file: StaticString = #filePath, line: UInt = #line) -> ChessEngine {
        let sut = ChessEngine(fen: fen)
        
        // Memory leak tracking standard
        addTeardownBlock { [weak sut] in
            XCTAssertNil(sut, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
        }
        
        return sut
    }
}
