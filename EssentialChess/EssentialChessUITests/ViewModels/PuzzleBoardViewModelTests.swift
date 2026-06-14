//
//  PuzzleBoardViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class PuzzleBoardViewModelTests: XCTestCase {
    
    func test_init_startsAtFrontierWhenThemeIsIncomplete() {
        let p1 = makePuzzle(id: "1")
        let p2 = makePuzzle(id: "2")
        let p3 = makePuzzle(id: "3")
        
        let (sut, _) = makeSUT(puzzles: [p1, p2, p3], completedIDs: ["1"])
        
        XCTAssertEqual(sut.currentActiveIndex, 1, "Expected to start at the first unsolved puzzle")
        XCTAssertEqual(sut.highestUnsolvedIndex, 1)
        XCTAssertEqual(sut.unlockedCount, 2, "Expected unlocked count to be highest unsolved + 1")
        XCTAssertFalse(sut.isThemeFullyCompleted)
    }
    
    func test_init_startsAtZeroWhenThemeIsFullyCompleted() {
        let p1 = makePuzzle(id: "1")
        let p2 = makePuzzle(id: "2")
        
        let (sut, _) = makeSUT(puzzles: [p1, p2], completedIDs: ["1", "2"])
        
        XCTAssertEqual(sut.currentActiveIndex, 0, "Expected to start at 0 for review when fully completed")
        XCTAssertEqual(sut.highestUnsolvedIndex, 0)
        XCTAssertEqual(sut.unlockedCount, 2)
        XCTAssertTrue(sut.isThemeFullyCompleted)
    }
    
    func test_markSolved_updatesStateAndTriggersCallback() {
        let p1 = makePuzzle(id: "1")
        var solvedIDs = [String]()
        let (sut, _) = makeSUT(puzzles: [p1], completedIDs: [], onPuzzleSolved: { solvedIDs.append($0) })
        
        sut.markSolved()
        
        XCTAssertTrue(sut.isSolved)
        XCTAssertEqual(solvedIDs, ["1"])
    }
    
    func test_markWrong_incrementsAttempts() {
        let (sut, _) = makeSUT(puzzles: [makePuzzle(id: "1")], completedIDs: [])
        
        sut.markWrong()
        sut.markWrong()
        
        XCTAssertEqual(sut.wrongAttempts, 2)
        XCTAssertFalse(sut.isSolved)
    }
    
    func test_triggerNext_jumpsToFrontierWhenReviewingOldPuzzle() {
        let p1 = makePuzzle(id: "1")
        let p2 = makePuzzle(id: "2")
        let (sut, _) = makeSUT(puzzles: [p1, p2], completedIDs: ["1"])
        
        // Simulate the user jumping back to review puzzle p1
        sut.jumpTo(index: 0)
        sut.triggerNext()
        
        XCTAssertEqual(sut.currentActiveIndex, 1, "Expected next button to jump back to the frontier")
        XCTAssertFalse(sut.isSessionComplete)
    }
    
    func test_triggerNext_completesSessionWhenLastPuzzleSolved() {
        let p1 = makePuzzle(id: "1")
        let (sut, _) = makeSUT(puzzles: [p1], completedIDs: [])
        
        sut.markSolved() // Now the local completedIDs contains ["1"]
        sut.triggerNext()
        
        XCTAssertTrue(sut.isSessionComplete)
    }
    
    func test_jumpTo_ignoresIndicesOutOfBounds() {
        let p1 = makePuzzle(id: "1")
        let p2 = makePuzzle(id: "2")
        let (sut, _) = makeSUT(puzzles: [p1, p2], completedIDs: []) // Only p1 is unlocked
        
        sut.jumpTo(index: 1) // Try jumping to p2 which is still locked
        
        XCTAssertEqual(sut.currentActiveIndex, 0, "Expected index to remain unchanged if jumping to locked puzzle")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        puzzles: [Puzzle],
        completedIDs: Set<String>,
        onPuzzleSolved: @escaping (String) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleBoardViewModel, onPuzzleSolved: (String) -> Void) {
        
        let sut = PuzzleBoardViewModel(
            puzzles: puzzles,
            initialCompletedIDs: completedIDs,
            onPuzzleSolved: onPuzzleSolved
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, onPuzzleSolved)
    }
    
    private func makePuzzle(id: String) -> Puzzle {
        return Puzzle(id: id, fen: "any", moves: [], rating: 1000, tags: [])
    }
}

