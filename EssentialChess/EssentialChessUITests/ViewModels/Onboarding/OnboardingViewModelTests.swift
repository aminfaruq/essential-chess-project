//
//  OnboardingViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class OnboardingViewModelTests: XCTestCase {
    
    func test_init_setsInitialStateAndFetchesFirstPuzzle() {
        let puzzle = makePuzzle(rating: 1500)
        let (sut, _) = makeSUT(pool: [puzzle], totalPuzzles: 1, baseRating: 1500.0)
        
        XCTAssertEqual(sut.currentRating, 1500.0)
        XCTAssertEqual(sut.currentPuzzleIndex, 0)
        XCTAssertFalse(sut.isComplete)
        XCTAssertEqual(sut.progress, 0.0)
        XCTAssertEqual(sut.currentPuzzle?.id, puzzle.id, "Expected first puzzle to be fetched on init")
    }
    
    func test_handleResult_updatesRatingAndFetchesNextPuzzleAdaptively() {
        let puzzle1 = makePuzzle(rating: 1500)
        let puzzle2 = makePuzzle(rating: 1700)
        let puzzle3 = makePuzzle(rating: 1300)
        
        // Provide 3 puzzles. We only need 2 iterations to test adaptive.
        let (sut, _) = makeSUT(pool: [puzzle1, puzzle2, puzzle3], totalPuzzles: 2, baseRating: 1500.0)
        
        // At start, it should pick puzzle1 (closest to 1500)
        XCTAssertEqual(sut.currentPuzzle?.id, puzzle1.id)
        
        // Answer correctly -> rating increases to 1550
        sut.handleResult(isCorrect: true)
        
        XCTAssertEqual(sut.currentRating, 1550.0)
        XCTAssertEqual(sut.currentPuzzleIndex, 1)
        XCTAssertFalse(sut.isComplete)
        XCTAssertEqual(sut.progress, 0.5)
        
        // Since rating is now 1550, it should dynamically fetch puzzle2 (rating 1550)
        XCTAssertEqual(sut.currentPuzzle?.id, puzzle2.id)
    }
    
    func test_handleResult_completesOnboardingAndRequiresCommitToTriggerCallback() {
        var completedRating: Double?
        let puzzle = makePuzzle(rating: 1500)
        let (sut, _) = makeSUT(pool: [puzzle], totalPuzzles: 1, baseRating: 1500.0) { finalRating in
            completedRating = finalRating
        }
        
        sut.handleResult(isCorrect: false) // Answered incorrectly -> rating decreases to 1450
        
        XCTAssertTrue(sut.isComplete)
        XCTAssertEqual(sut.currentRating, 1450.0)
        XCTAssertNil(completedRating, "Expected completion callback to NOT be called yet")
        XCTAssertEqual(sut.progress, 1.0)
        
        sut.commitResults()
        
        XCTAssertEqual(completedRating, 1450.0, "Expected completion callback to be called with final rating after commitResults()")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        pool: [Puzzle],
        totalPuzzles: Int,
        baseRating: Double,
        onComplete: @escaping (Double) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: OnboardingViewModel, onComplete: (Double) -> Void) {
        
        let calculator = RatingCalculator()
        let ratingLogic: (Double, Double, Bool) -> Double = { current, puzzleRating, isCorrect in
            calculator.calculatePlacementRating(current: current, puzzleRating: puzzleRating, isCorrect: isCorrect)
        }
        
        let sut = OnboardingViewModel(
            pool: pool,
            totalPuzzles: totalPuzzles,
            initialRating: baseRating,
            calculateRating: ratingLogic,
            onComplete: onComplete
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, onComplete)
    }
    
    private func makePuzzle(rating: Int = 1000) -> Puzzle {
        return Puzzle(id: UUID().uuidString, fen: "any", moves: [], rating: rating, tags: [])
    }
}
