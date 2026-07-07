//
//  PuzzleStreakViewModelTests.swift
//  EssentialChess
//
//  Created by App on 15/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class PuzzleStreakViewModelTests: XCTestCase {
    
    func test_handlePuzzleCompletion_correctMove_increasesStreakAndScalesDifficulty() {
        let pool = [
            makePuzzle(id: "1", rating: 500),
            makePuzzle(id: "2", rating: 550)
        ]
        let sut = makeSUT(pool: pool)
        
        let firstPuzzleId = sut.currentPuzzle?.id
        sut.handlePuzzleCompletion(isCorrect: true)
        let secondPuzzleId = sut.currentPuzzle?.id
        
        XCTAssertEqual(sut.currentStreak, 1, "Expected streak score to increase by 1")
        XCTAssertNotEqual(firstPuzzleId, secondPuzzleId, "Expected next puzzle to be different")
        
        let loadedRating = sut.currentPuzzle?.rating ?? 0
        XCTAssertTrue((450...650).contains(loadedRating), "Expected next puzzle with higher difficulty (target 550 +/- 100) to be presented")
        
        XCTAssertFalse(sut.isPuzzleFinished, "Expected puzzle finished state to remain false to allow continuous play")
    }

    // MARK: - Helpers
    
    private func makeSUT(
        pool: [Puzzle]? = nil,
        activeStreak: Int = 0,
        activeUsedIDs: Set<String> = [],
        highestStreak: Int = 0,
        onStreakUpdated: @escaping (Int, Set<String>) -> Void = { _, _ in },
        onSessionFinished: @escaping (Int) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PuzzleStreakViewModel {
        
        let puzzles = pool ?? [makePuzzle(id: "default", rating: 500)]
        
        let sut = PuzzleStreakViewModel(
            pool: puzzles,
            activeStreak: activeStreak,
            activeUsedIDs: activeUsedIDs,
            highestStreak: highestStreak,
            onStreakUpdated: onStreakUpdated,
            onSessionFinished: onSessionFinished,
            updateDailyLimits: { _, _ in }, onPuzzleSolved: {}
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makePuzzle(id: String, rating: Int) -> Puzzle {
        return Puzzle(id: id, fen: "any", moves: [], rating: rating, tags: [])
    }
}
