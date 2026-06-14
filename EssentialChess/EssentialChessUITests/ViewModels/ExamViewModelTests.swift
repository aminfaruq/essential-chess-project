//
//  ExamViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class ExamViewModelTests: XCTestCase {
    
    func test_init_setsInitialActiveState() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        
        XCTAssertEqual(sut.remainingLives, 3)
        XCTAssertEqual(sut.solvedCount, 0)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.phase, .active)
    }
    
    func test_handleCorrect_advancesPuzzleAndIncrementsSolvedCount() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])
        
        sut.handleCorrect()
        
        XCTAssertEqual(sut.solvedCount, 1)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.phase, .active)
    }
    
    func test_handleCorrect_triggersOnPassedWhenAllPuzzlesSolved() {
        var passedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onPassed: { passedCallCount += 1 })
        
        sut.handleCorrect()
        
        XCTAssertEqual(sut.phase, .passed)
        XCTAssertEqual(passedCallCount, 1, "Expected onPassed to be called exactly once")
    }
    
    func test_handleIncorrect_decrementsLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])
        
        sut.handleIncorrect()
        
        XCTAssertEqual(sut.remainingLives, 2)
        XCTAssertEqual(sut.phase, .active)
    }
    
    func test_handleIncorrect_triggersOnFailedWhenLivesReachZero() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })
        
        sut.handleIncorrect() // 2 lives left
        sut.handleIncorrect() // 1 life left
        sut.handleIncorrect() // 0 lives left
        
        XCTAssertEqual(sut.phase, .failed)
        XCTAssertEqual(failedCallCount, 1, "Expected onFailed to be called exactly once")
    }
    
    func test_handleHint_decrementsLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        
        sut.handleHint()
        
        XCTAssertEqual(sut.remainingLives, 2)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        puzzles: [Puzzle],
        onPassed: @escaping () -> Void = {},
        onFailed: @escaping () -> Void = {},
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ExamViewModel, onPassed: () -> Void, onFailed: () -> Void) {
        
        let sut = ExamViewModel(puzzles: puzzles, onPassed: onPassed, onFailed: onFailed)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, onPassed, onFailed)
    }
    
    private func makePuzzle() -> Puzzle {
        return Puzzle(id: UUID().uuidString, fen: "any", moves: [], rating: 1000, tags: [])
    }
}
