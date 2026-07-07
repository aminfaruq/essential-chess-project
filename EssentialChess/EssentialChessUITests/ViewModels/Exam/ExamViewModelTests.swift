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

    // MARK: - Init Tests

    func test_init_setsInitialActiveState() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])

        XCTAssertEqual(sut.remainingLives, 3)
        XCTAssertEqual(sut.solvedCount, 0)
        XCTAssertEqual(sut.currentIndex, 0)
        XCTAssertEqual(sut.phase, .active)
    }

    func test_init_withEmptyPuzzles_totalPuzzlesIsZero() {
        let (sut, _, _) = makeSUT(puzzles: [])

        XCTAssertEqual(sut.totalPuzzles, 0)
        XCTAssertNil(sut.currentPuzzle)
        XCTAssertEqual(sut.phase, .active)
    }

    // MARK: - Computed Properties

    func test_currentPuzzle_returnsPuzzleAtIndex() {
        let puzzle = makePuzzle()
        let (sut, _, _) = makeSUT(puzzles: [puzzle, makePuzzle()])

        XCTAssertEqual(sut.currentPuzzle?.id, puzzle.id)
    }

    func test_currentPuzzle_returnsNilWhenIndexOutOfBounds() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleCorrect()

        XCTAssertNil(sut.currentPuzzle)
    }

    func test_totalPuzzles_returnsPuzzleCount() {
        let puzzles = [makePuzzle(), makePuzzle(), makePuzzle()]
        let (sut, _, _) = makeSUT(puzzles: puzzles)

        XCTAssertEqual(sut.totalPuzzles, 3)
    }

    // MARK: - handleCorrect Tests

    func test_handleCorrect_advancesPuzzleAndIncrementsSolvedCount() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.handleCorrect()

        XCTAssertEqual(sut.solvedCount, 1)
        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.phase, .active)
    }

    func test_handleCorrect_doesNotDecrementLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.handleCorrect()

        XCTAssertEqual(sut.remainingLives, 3)
    }

    func test_handleCorrect_triggersOnPassedWhenAllPuzzlesSolved() {
        var passedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onPassed: { passedCallCount += 1 })

        sut.handleCorrect()

        XCTAssertEqual(sut.phase, .passed)
        XCTAssertEqual(passedCallCount, 1)
    }

    func test_handleCorrect_doesNothingWhenPhaseIsPassed() {
        var passedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onPassed: { passedCallCount += 1 })
        sut.handleCorrect()

        sut.handleCorrect()

        XCTAssertEqual(sut.solvedCount, 1, "Solved count should not increase after passing")
        XCTAssertEqual(passedCallCount, 1, "onPassed should not be called again")
    }

    func test_handleCorrect_doesNothingWhenPhaseIsFailed() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleIncorrect()
        sut.handleIncorrect()
        sut.handleIncorrect()

        sut.handleCorrect()

        XCTAssertEqual(sut.solvedCount, 0, "Solved count should not increase after failing")
    }

    // MARK: - handleIncorrect Tests

    func test_handleIncorrect_decrementsLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.handleIncorrect()

        XCTAssertEqual(sut.remainingLives, 2)
        XCTAssertEqual(sut.phase, .active)
    }

    func test_handleIncorrect_doesNotAdvancePuzzleIndex() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.handleIncorrect()

        XCTAssertEqual(sut.currentIndex, 0, "Incorrect answer should not advance puzzle")
    }

    func test_handleIncorrect_triggersOnFailedWhenLivesReachZero() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })

        sut.handleIncorrect()
        sut.handleIncorrect()
        sut.handleIncorrect()

        XCTAssertEqual(sut.phase, .failed)
        XCTAssertEqual(sut.remainingLives, 0)
        XCTAssertEqual(failedCallCount, 1)
    }

    func test_handleIncorrect_doesNothingWhenPhaseIsFailed() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })
        sut.handleIncorrect()
        sut.handleIncorrect()
        sut.handleIncorrect()

        sut.handleIncorrect()

        XCTAssertEqual(sut.remainingLives, 0, "Lives should not go below 0")
        XCTAssertEqual(failedCallCount, 1, "onFailed should not be called again")
    }

    func test_handleIncorrect_doesNothingWhenPhaseIsPassed() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleCorrect()

        sut.handleIncorrect()

        XCTAssertEqual(sut.remainingLives, 3, "Lives should not change after passing")
    }

    // MARK: - handleHint Tests

    func test_handleHint_decrementsLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])

        sut.handleHint()

        XCTAssertEqual(sut.remainingLives, 2)
    }

    func test_handleHint_doesNotAdvancePuzzleIndex() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.handleHint()

        XCTAssertEqual(sut.currentIndex, 0)
    }

    func test_handleHint_triggersOnFailedWhenLivesReachZero() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })

        sut.handleHint()
        sut.handleHint()
        sut.handleHint()

        XCTAssertEqual(sut.phase, .failed)
        XCTAssertEqual(failedCallCount, 1)
    }

    func test_handleHint_doesNothingWhenPhaseIsFailed() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleHint()
        sut.handleHint()
        sut.handleHint()

        sut.handleHint()

        XCTAssertEqual(sut.remainingLives, 0)
    }

    func test_handleHint_doesNothingWhenPhaseIsPassed() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleCorrect()

        sut.handleHint()

        XCTAssertEqual(sut.remainingLives, 3)
    }

    // MARK: - skipPuzzle Tests

    func test_skipPuzzle_advancesIndexButNotSolvedCount() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle()])

        sut.skipPuzzle()

        XCTAssertEqual(sut.currentIndex, 1)
        XCTAssertEqual(sut.solvedCount, 0, "Skipping should not increment solved count")
        XCTAssertEqual(sut.phase, .active)
    }

    func test_skipPuzzle_triggersOnFailedWhenSkippingLastPuzzle() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })

        sut.skipPuzzle()

        XCTAssertEqual(sut.phase, .failed)
        XCTAssertEqual(failedCallCount, 1)
    }

    func test_skipPuzzle_doesNothingWhenPhaseIsFailed() {
        var failedCallCount = 0
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()], onFailed: { failedCallCount += 1 })
        sut.skipPuzzle()

        sut.skipPuzzle()

        XCTAssertEqual(failedCallCount, 1, "onFailed should not be called again after failing")
    }

    func test_skipPuzzle_doesNothingWhenPhaseIsPassed() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle()])
        sut.handleCorrect()

        sut.skipPuzzle()

        XCTAssertEqual(sut.currentIndex, 1, "Index should not advance after passing")
    }

    // MARK: - Mixed Action Tests

    func test_mixedCorrectAndIncorrect_maintainsCorrectState() {
        let puzzles = [makePuzzle(), makePuzzle(), makePuzzle(), makePuzzle()]
        let (sut, _, _) = makeSUT(puzzles: puzzles)

        sut.handleCorrect()
        sut.handleIncorrect()
        sut.handleCorrect()

        XCTAssertEqual(sut.solvedCount, 2)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.remainingLives, 2)
        XCTAssertEqual(sut.phase, .active)
    }

    func test_mixedHintsAndCorrect_triggersFailOnFinalMistake() {
        var failedCallCount = 0
        let puzzles = [makePuzzle(), makePuzzle(), makePuzzle()]
        let (sut, _, _) = makeSUT(puzzles: puzzles, onFailed: { failedCallCount += 1 })

        sut.handleCorrect()
        sut.handleHint()
        sut.handleCorrect()
        sut.handleHint()

        XCTAssertEqual(sut.solvedCount, 2)
        XCTAssertEqual(sut.currentIndex, 2)
        XCTAssertEqual(sut.remainingLives, 1)
        XCTAssertEqual(sut.phase, .active)

        sut.handleIncorrect()

        XCTAssertEqual(sut.phase, .failed)
        XCTAssertEqual(sut.remainingLives, 0)
        XCTAssertEqual(failedCallCount, 1)
    }

    func test_skipDoesNotAffectLives() {
        let (sut, _, _) = makeSUT(puzzles: [makePuzzle(), makePuzzle(), makePuzzle()])

        sut.skipPuzzle()

        XCTAssertEqual(sut.remainingLives, 3, "Skip should not affect lives")
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
