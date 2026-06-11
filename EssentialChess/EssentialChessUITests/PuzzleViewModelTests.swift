//
//  PuzzleViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class PuzzleViewModelTests: XCTestCase {
    
    func test_init_setsInitialState() {
        let (sut, _) = makeSUT(userColorName: "White")
        
        XCTAssertFalse(sut.isSolved)
        XCTAssertEqual(sut.wrongAttempts, 0)
        XCTAssertEqual(sut.showMoveInfo(), "White to Move")
    }
    
    func test_load_resetsState() {
        let (sut, _) = makeSUT()
        
        sut.markSolved()
        sut.markWrong()
        sut.load(makePuzzle())
        
        XCTAssertFalse(sut.isSolved, "Expected load to reset isSolved state")
        XCTAssertEqual(sut.wrongAttempts, 0, "Expected load to reset wrongAttempts")
    }
    
    func test_markSolved_updatesState() {
        let (sut, _) = makeSUT()
        
        sut.markSolved()
        
        XCTAssertTrue(sut.isSolved)
    }
    
    func test_markWrong_incrementsAttempts() {
        let (sut, _) = makeSUT()
        
        sut.markWrong()
        sut.markWrong()
        
        XCTAssertEqual(sut.wrongAttempts, 2)
        XCTAssertFalse(sut.isSolved)
    }
    
    func test_showHint_triggersCallback() {
        var hintTriggerCount = 0
        let (sut, _) = makeSUT(onShowHint: { hintTriggerCount += 1 })
        
        sut.showHint()
        sut.showHint()
        
        XCTAssertEqual(hintTriggerCount, 2, "Expected onShowHint callback to be triggered exactly twice")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        userColorName: String = "White",
        onShowHint: @escaping () -> Void = {},
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleViewModel, onShowHint: () -> Void) {
        
        let sut = PuzzleViewModel(userColorName: userColorName, onShowHint: onShowHint)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, onShowHint)
    }
    
    private func makePuzzle() -> Puzzle {
        return Puzzle(id: UUID().uuidString, fen: "any", moves: [], rating: 1000, tags: [])
    }
}
