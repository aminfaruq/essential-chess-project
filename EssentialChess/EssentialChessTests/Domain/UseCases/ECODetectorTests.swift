//
//  ECODetectorTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class ECODetectorTests: XCTestCase {
    
    func test_detect_returnsNilOnEmptyDatabase() {
        let sut = makeSUT(database: [:])
        
        let result = sut.detect(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        
        XCTAssertNil(result)
    }
    
    func test_detect_matchesExactFENWithoutClocks() {
        let expectedOpening = ECOOpening(eco: "C20", name: "King's Pawn Game")
        // Dictionary key has no clocks
        let database = ["rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": expectedOpening]
        let sut = makeSUT(database: database)
        
        // Input FEN has no clocks
        let result = sut.detect(fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -")
        
        XCTAssertEqual(result, expectedOpening)
    }
    
    func test_detect_matchesFENByStrippingClocksFromInput() {
        let expectedOpening = ECOOpening(eco: "C20", name: "King's Pawn Game")
        // Dictionary key has no clocks
        let database = ["rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": expectedOpening]
        let sut = makeSUT(database: database)
        
        // Input FEN has clocks (0 1 or 0 2)
        let result = sut.detect(fen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        
        XCTAssertEqual(result, expectedOpening)
    }
    
    func test_detect_returnsNilWhenNoMatchFound() {
        let database = ["rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -": ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)
        
        // Input FEN is different
        let result = sut.detect(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        
        XCTAssertNil(result)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(database: [String: ECOOpening] = [:], file: StaticString = #filePath, line: UInt = #line) -> ECODetector {
        let sut = ECODetector(database: database)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
