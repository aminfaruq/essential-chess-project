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
    
    func test_init_setsInitialState() {
        let (sut, _) = makeSUT(puzzles: [makePuzzle()], baseRating: 1500.0)
        
        XCTAssertEqual(sut.currentRating, 1500.0)
        XCTAssertEqual(sut.currentPuzzleIndex, 0)
        XCTAssertFalse(sut.isComplete)
        XCTAssertEqual(sut.progress, 0.0)
    }
    
    func test_handleResult_updatesRatingAndAdvancesPuzzle() {
        // Provide 2 puzzles so that after answering 1, the status is not yet complete
        let (sut, _) = makeSUT(puzzles: [makePuzzle(rating: 1500), makePuzzle(rating: 1500)], baseRating: 1500.0)
        
        // Assumption: initial rating 1500, puzzle 1500, answered correctly (isCorrect: true) -> rating increases to 1550
        sut.handleResult(isCorrect: true)
        
        XCTAssertEqual(sut.currentRating, 1550.0)
        XCTAssertEqual(sut.currentPuzzleIndex, 1)
        XCTAssertFalse(sut.isComplete)
        XCTAssertEqual(sut.progress, 0.5) // 1 out of 2 puzzles completed
    }
    
    func test_handleResult_completesOnboardingAndTriggersCallback() {
        var completedRating: Double?
        let (sut, _) = makeSUT(puzzles: [makePuzzle(rating: 1500)], baseRating: 1500.0) { finalRating in
            completedRating = finalRating
        }
        
        sut.handleResult(isCorrect: false) // Answered incorrectly -> rating decreases to 1450
        
        XCTAssertTrue(sut.isComplete)
        XCTAssertEqual(sut.currentRating, 1450.0)
        XCTAssertEqual(completedRating, 1450.0, "Expected completion callback to be called with final rating")
        XCTAssertEqual(sut.progress, 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        puzzles: [Puzzle],
        baseRating: Double,
        onComplete: @escaping (Double) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: OnboardingViewModel, onComplete: (Double) -> Void) {
        
        // Inject the pure function from RatingCalculator as a dependency
        let calculator = RatingCalculator()
        let ratingLogic: (Double, Double, Bool) -> Double = { current, puzzleRating, isCorrect in
            calculator.calculatePlacementRating(current: current, puzzleRating: puzzleRating, isCorrect: isCorrect)
        }
        
        let sut = OnboardingViewModel(
            puzzles: puzzles,
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
