//
//  PuzzleMixViewModelTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 15/06/26.
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class PuzzleMixViewModelTests: XCTestCase {
    
    // MARK: - Scenario: Initializing actual rating for the first time
    
    func test_init_withNullActualRating_initializesWithHiddenRatingAndSaves() {
        var savedRatings = [Double]()
        let hiddenRating = 1350.0
        
        let sut = makeSUT(hiddenRating: hiddenRating, actualRating: nil, saveActualRating: { rating in
            savedRatings.append(rating)
        })
        
        XCTAssertEqual(sut.actualRating, 1350.0, "Expected actualRating to initialize to hiddenRating")
        XCTAssertEqual(savedRatings, [1350.0], "Expected to save the newly initialized actual rating")
    }
    
    func test_init_withExistingActualRating_usesExistingActualRating_andDoesNotSave() {
        var savedRatings = [Double]()
        
        let sut = makeSUT(hiddenRating: 1350.0, actualRating: 1200.0, saveActualRating: { rating in
            savedRatings.append(rating)
        })
        
        XCTAssertEqual(sut.actualRating, 1200.0)
        XCTAssertTrue(savedRatings.isEmpty)
    }
    
    // MARK: - Scenario: Dynamic puzzle fetching based on actual rating
    
    func test_init_fetchesPuzzleWithinAcceptableRange() {
        let pool = [
            makePuzzle(id: "1", rating: 900),
            makePuzzle(id: "2", rating: 1250), // within range of 1200 +/- 150
            makePuzzle(id: "3", rating: 1500)
        ]
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0)
        
        XCTAssertEqual(sut.currentPuzzle?.id, "2", "Expected to fetch a puzzle within +/- 150 of 1200")
    }
    
    // MARK: - Scenario: Correct solution increases actual rating
    
    func test_handlePuzzleCompletion_correctMove_increasesRatingAndAllowsProgression() {
        let pool = [makePuzzle(id: "1", rating: 1200)]
        var savedRatings = [Double]()
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0, calculateRating: { rating, _, isCorrect in
            return isCorrect ? rating + 15 : rating - 15
        }, saveActualRating: { rating in
            savedRatings.append(rating)
        })
        
        sut.handlePuzzleCompletion(isCorrect: true)
        
        XCTAssertEqual(sut.actualRating, 1215.0, "Expected actualRating to increase")
        XCTAssertEqual(savedRatings, [1215.0], "Expected updated rating to be saved immediately")
        XCTAssertTrue(sut.isPuzzleFinished, "Expected progression to be allowed")
        XCTAssertFalse(sut.showCorrectMove, "Expected not to show correct move for a correct answer")
    }
    
    // MARK: - Scenario: Incorrect solution decreases actual rating
    
    func test_handlePuzzleCompletion_incorrectMove_decreasesRatingAndShowsCorrectMoveAndAllowsProgression() {
        let pool = [makePuzzle(id: "1", rating: 1200)]
        var savedRatings = [Double]()
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0, calculateRating: { rating, _, isCorrect in
            return isCorrect ? rating + 15 : rating - 15
        }, saveActualRating: { rating in
            savedRatings.append(rating)
        })
        
        sut.handlePuzzleCompletion(isCorrect: false)
        
        XCTAssertEqual(sut.actualRating, 1185.0, "Expected actualRating to decrease")
        XCTAssertEqual(savedRatings, [1185.0], "Expected updated rating to be saved immediately")
        XCTAssertTrue(sut.isPuzzleFinished, "Expected progression to be allowed")
        XCTAssertTrue(sut.showCorrectMove, "Expected to reveal the correct move")
    }
    
    // MARK: - Scenario: Uninterrupted endless progression
    
    func test_handleHint_decreasesRatingAndMarksFailed_butAllowsProgression() {
        let pool = [makePuzzle(id: "1", rating: 1200)]
        var savedRatings = [Double]()
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0, calculateRating: { rating, _, isCorrect in
            return isCorrect ? rating + 15 : rating - 15
        }, saveActualRating: { rating in
            savedRatings.append(rating)
        })
        
        sut.handleHint()
        
        XCTAssertEqual(sut.actualRating, 1185.0, "Expected actualRating to decrease on hint")
        XCTAssertEqual(savedRatings, [1185.0], "Expected updated rating to be saved immediately")
        XCTAssertTrue(sut.isPuzzleFinished, "Expected progression to be allowed (shows Next button)")
        XCTAssertTrue(sut.hasUsedHint, "Expected hasUsedHint to be true")
        
        // Simulating the user finishing the puzzle after clicking hint
        sut.handlePuzzleCompletion(isCorrect: true)
        
        // Rating should not increase because the puzzle is already marked finished
        XCTAssertEqual(sut.actualRating, 1185.0, "Expected actualRating not to change if completed after hint")
    }
    
    func test_onNextTapped_presentsNewPuzzle() {
        let pool = [
            makePuzzle(id: "1", rating: 1200),
            makePuzzle(id: "2", rating: 1200)
        ]
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0)
        
        let firstPuzzleId = sut.currentPuzzle?.id
        
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.onNextTapped()
        
        let secondPuzzleId = sut.currentPuzzle?.id
        
        XCTAssertNotEqual(firstPuzzleId, secondPuzzleId, "Expected a new puzzle to be presented")
        XCTAssertFalse(sut.isPuzzleFinished, "Expected puzzle finished state to reset")
        XCTAssertFalse(sut.showCorrectMove, "Expected correct move state to reset")
    }
    
    // MARK: - Fallback Scenarios
    
    func test_loadNextPuzzle_withNoPuzzlesInRange_fetchesClosestRatingPuzzle() {
        let pool = [
            makePuzzle(id: "1", rating: 800),
            makePuzzle(id: "2", rating: 1400)
        ]
        
        let sut = makeSUT(pool: pool, actualRating: 1200.0)
        
        // Neither 800 nor 1400 are within +/- 150 of 1200.
        // Closest is 1400 (diff 200) vs 800 (diff 400).
        XCTAssertEqual(sut.currentPuzzle?.id, "2", "Expected to fallback to the puzzle with the closest rating")
    }
    
    func test_loadNextPuzzle_withAllPuzzlesSolved_cyclesPool() {
        let pool = [makePuzzle(id: "1", rating: 1200)]
        let sut = makeSUT(pool: pool, actualRating: 1200.0)
        
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.onNextTapped() // Should clear solved and present "1" again
        
        XCTAssertEqual(sut.currentPuzzle?.id, "1", "Expected to cycle the pool and present the puzzle again")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        pool: [Puzzle]? = nil,
        hiddenRating: Double = 500.0,
        actualRating: Double? = nil,
        calculateRating: @escaping (Double, Double, Bool) -> Double = { rating, _, _ in rating },
        saveActualRating: @escaping (Double) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PuzzleMixViewModel {
        
        let puzzles = pool ?? [makePuzzle(id: "default", rating: Int(actualRating ?? hiddenRating))]
        
        let sut = PuzzleMixViewModel(
            pool: puzzles,
            hiddenRating: hiddenRating,
            actualRating: actualRating,
            calculateRating: calculateRating,
            saveActualRating: saveActualRating,
            onPuzzleSolved: {}
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makePuzzle(id: String, rating: Int) -> Puzzle {
        return Puzzle(id: id, fen: "any", moves: [], rating: rating, tags: [])
    }
}
