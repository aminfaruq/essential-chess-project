//
//  OpeningRecognitionViewModelTests.swift
//  EssentialChessUITests
//

import XCTest
import EssentialChess
import EssentialChessUI

final class OpeningRecognitionViewModelTests: XCTestCase {
    
    func test_init_setsDefaultStartingState() {
        let sut = makeSUT()
        
        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }
    
    func test_onMove_updatesStateWhenOpeningIsFound() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)
        
        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")
        XCTAssertEqual(sut.currentECO, "C20")
    }
    
    func test_onMove_retainsPreviousStateWhenOpeningIsNotFound() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)
        
        // 1. Play a known move
        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        
        // 2. Play an unknown move
        sut.onMove(resultingFen: "r1bqkbnr/pppp1ppp/2n5/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R w KQkq - 0 3")
        
        // State should remain as the last known
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")
        XCTAssertEqual(sut.currentECO, "C20")
    }
    
    func test_onMove_resetsToStartingPositionWhenReachingInitialFen() {
        let knownFEN = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq -"
        let database = [knownFEN: ECOOpening(eco: "C20", name: "King's Pawn Game")]
        let sut = makeSUT(database: database)
        
        // 1. Play a known move
        sut.onMove(resultingFen: "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2")
        XCTAssertEqual(sut.currentOpeningName, "King's Pawn Game")
        
        // 2. Undo back to starting position (full FEN)
        sut.onMove(resultingFen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        
        // State should reset
        XCTAssertEqual(sut.currentOpeningName, "Starting Position")
        XCTAssertEqual(sut.currentECO, "")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(database: [String: ECOOpening] = [:], file: StaticString = #filePath, line: UInt = #line) -> OpeningRecognitionViewModel {
        let detector = ECODetector(database: database)
        let sut = OpeningRecognitionViewModel(detector: detector)
        
        trackForMemoryLeaks(detector, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
}
