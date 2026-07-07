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

    // MARK: - Init Tests

    func test_init_setsInitialPublishedState() {
        let (sut, _) = makeSUT()

        XCTAssertNotNil(sut.currentPuzzle, "Expected first puzzle to be loaded on init")
        XCTAssertEqual(sut.currentStreak, 0)
        XCTAssertFalse(sut.isPuzzleFinished)
        XCTAssertFalse(sut.hasFailed)
        XCTAssertFalse(sut.showCorrectMove)
        XCTAssertFalse(sut.isNewRecord)
        XCTAssertFalse(sut.showResultOverlay)
        XCTAssertEqual(sut.currentHighestStreak, 0)
    }

    func test_init_restoresActiveStreak() {
        let (sut, _) = makeSUT(activeStreak: 3)

        XCTAssertEqual(sut.currentStreak, 3)
    }

    func test_init_respectsActiveUsedIDs() {
        let pool = [
            makePuzzle(id: "used", rating: 500),
            makePuzzle(id: "unused", rating: 500)
        ]
        let (sut, _) = makeSUT(pool: pool, activeUsedIDs: ["used"])

        XCTAssertEqual(sut.currentPuzzle?.id, "unused", "Expected used puzzle to be excluded")
    }

    func test_init_setsHighestStreak() {
        let (sut, _) = makeSUT(highestStreak: 10)

        XCTAssertEqual(sut.currentHighestStreak, 10)
    }

    // MARK: - handlePuzzleCompletion (Correct) Tests

    func test_handlePuzzleCompletion_correctMove_increasesStreak() {
        let (sut, _) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentStreak, 1)
    }

    func test_handlePuzzleCompletion_correctMove_loadsNextPuzzle() {
        let pool = [
            makePuzzle(id: "1", rating: 500),
            makePuzzle(id: "2", rating: 500)
        ]
        let (sut, _) = makeSUT(pool: pool)
        let firstPuzzleId = sut.currentPuzzle?.id

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertNotNil(sut.currentPuzzle)
        XCTAssertNotEqual(sut.currentPuzzle?.id, firstPuzzleId, "Expected a different puzzle to be loaded")
    }

    func test_handlePuzzleCompletion_correctMove_callsOnPuzzleSolved() {
        let (sut, spy) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(spy.puzzleSolvedCount, 1)
    }

    func test_handlePuzzleCompletion_correctMove_callsOnStreakUpdated() {
        let (sut, spy) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(spy.streakUpdates.count, 2, "Expected init + completion callbacks")
        XCTAssertEqual(spy.streakUpdates.last?.streak, 1)
        XCTAssertFalse(spy.streakUpdates.last?.usedIDs.isEmpty ?? true)
    }

    func test_handlePuzzleCompletion_correctMove_doesNotFinishPuzzle() {
        let (sut, _) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertFalse(sut.isPuzzleFinished)
        XCTAssertFalse(sut.hasFailed)
        XCTAssertFalse(sut.showCorrectMove)
    }

    func test_handlePuzzleCompletion_correctMove_scalesDifficultyWithStreak() {
        let pool = (500...1200).filter { $0 % 50 == 0 }.map {
            makePuzzle(id: "\($0)", rating: $0)
        }
        let (sut, _) = makeSUT(pool: pool)
        let firstRating = sut.currentPuzzle?.rating ?? 0

        sut.handlePuzzleCompletion(isCorrect: true)
        let secondRating = sut.currentPuzzle?.rating ?? 0

        XCTAssertEqual(sut.currentStreak, 1)
        XCTAssertNotNil(sut.currentPuzzle)

        sut.handlePuzzleCompletion(isCorrect: true)
        let thirdRating = sut.currentPuzzle?.rating ?? 0

        XCTAssertEqual(sut.currentStreak, 2)
        XCTAssertNotNil(sut.currentPuzzle)
        XCTAssertEqual(Set([firstRating, secondRating, thirdRating]).count, 3,
            "Expected three distinct puzzles, got ratings: \(firstRating), \(secondRating), \(thirdRating)")
    }

    // MARK: - handlePuzzleCompletion (Incorrect) Tests

    func test_handlePuzzleCompletion_incorrectMove_setsFailureFlags() {
        let (sut, _) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertTrue(sut.hasFailed)
        XCTAssertTrue(sut.isPuzzleFinished)
        XCTAssertTrue(sut.showCorrectMove)
    }

    func test_handlePuzzleCompletion_incorrectMove_setsIsNewRecordWhenStreakExceedsHighest() {
        let (sut, _) = makeSUT(highestStreak: 0)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertTrue(sut.isNewRecord, "Streak 2 > highest 0 should be a new record")
    }

    func test_handlePuzzleCompletion_incorrectMove_doesNotSetIsNewRecordWhenStreakBelowHighest() {
        let (sut, _) = makeSUT(highestStreak: 10)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertFalse(sut.isNewRecord, "Streak 1 ≤ highest 10 should not be a new record")
    }

    func test_handlePuzzleCompletion_incorrectMove_doesNotSetIsNewRecordWhenStreakEqualsHighest() {
        let (sut, _) = makeSUT(highestStreak: 2)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertFalse(sut.isNewRecord, "Streak 2 ≤ highest 2 should not be a new record")
    }

    func test_handlePuzzleCompletion_incorrectMove_callsOnStreakUpdatedWithZero() {
        let (sut, spy) = makeSUT()
        spy.streakUpdates = []

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(spy.streakUpdates.count, 1)
        XCTAssertEqual(spy.streakUpdates.first?.streak, 0)
        XCTAssertEqual(spy.streakUpdates.first?.usedIDs, [])
    }

    func test_handlePuzzleCompletion_incorrectMove_callsOnSessionFinished() {
        let (sut, spy) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(spy.sessionFinishedScores, [2])
    }

    func test_handlePuzzleCompletion_incorrectMove_showsResultOverlayAfterDelay() {
        let (sut, _) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertFalse(sut.showResultOverlay, "Overlay should not show immediately")

        let exp = expectation(description: "Wait for overlay delay")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)

        XCTAssertTrue(sut.showResultOverlay, "Overlay should show after 1.5s delay")
    }

    func test_handlePuzzleCompletion_incorrectMove_keepsCurrentPuzzle() {
        let (sut, _) = makeSUT()
        let puzzleBeforeFail = sut.currentPuzzle

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(sut.currentPuzzle?.id, puzzleBeforeFail?.id, "Puzzle should not change on failure")
    }

    // MARK: - handlePuzzleCompletion When Already Finished

    func test_handlePuzzleCompletion_whenAlreadyFinished_correctDoesNothing() {
        let (sut, spy) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: false)
        let streakAfterFail = sut.currentStreak
        spy.puzzleSolvedCount = 0

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentStreak, streakAfterFail, "Streak should not change when already finished")
        XCTAssertEqual(spy.puzzleSolvedCount, 0, "onPuzzleSolved should not be called when already finished")
    }

    func test_handlePuzzleCompletion_whenAlreadyFinished_incorrectDoesNothing() {
        let (sut, spy) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: false)
        spy.sessionFinishedScores = []

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(spy.sessionFinishedScores.count, 0, "onSessionFinished should not be called again")
    }

    // MARK: - onNextTapped Tests

    func test_onNextTapped_resetsStateFlags() {
        let (sut, _) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: false)

        sut.onNextTapped()

        XCTAssertFalse(sut.hasFailed)
        XCTAssertFalse(sut.isPuzzleFinished)
        XCTAssertFalse(sut.showCorrectMove)
        XCTAssertFalse(sut.showResultOverlay)
        XCTAssertFalse(sut.isNewRecord)
    }

    func test_onNextTapped_resetsStreakAndLoadsPuzzle() {
        let (sut, _) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.onNextTapped()

        XCTAssertEqual(sut.currentStreak, 0)
        XCTAssertNotNil(sut.currentPuzzle)
    }

    func test_onNextTapped_callsOnStreakUpdatedWithZero() {
        let (sut, spy) = makeSUT()
        sut.handlePuzzleCompletion(isCorrect: false)
        spy.streakUpdates = []

        sut.onNextTapped()

        XCTAssertEqual(spy.streakUpdates.count, 2, "onNextTapped calls onStreakUpdated directly and via loadNextPuzzle")
        XCTAssertEqual(spy.streakUpdates.first?.streak, 0)
        XCTAssertEqual(spy.streakUpdates.first?.usedIDs, [])
    }

    func test_onNextTapped_updatesHighestStreakOnNewRecord() {
        let (sut, _) = makeSUT(highestStreak: 0)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertTrue(sut.isNewRecord)

        sut.onNextTapped()

        XCTAssertEqual(sut.currentHighestStreak, 2, "Expected highest streak to update to 2")
    }

    func test_onNextTapped_doesNotUpdateHighestStreakIfNotRecord() {
        let (sut, _) = makeSUT(highestStreak: 10)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: false)

        sut.onNextTapped()

        XCTAssertEqual(sut.currentHighestStreak, 10, "Expected highest streak to remain unchanged")
    }

    // MARK: - loadNextPuzzle Edge Cases

    func test_loadNextPuzzle_whenAllPuzzlesUsed_resetsAndReuses() {
        let pool = [makePuzzle(id: "only", rating: 500)]
        let (sut, _) = makeSUT(pool: pool)

        XCTAssertEqual(sut.currentPuzzle?.id, "only")

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentPuzzle?.id, "only", "Expected fallback to reuse puzzle when pool exhausted")
        XCTAssertEqual(sut.currentStreak, 1)
    }

    func test_loadNextPuzzle_filtersOutUsedPuzzleIDs() {
        let pool = [
            makePuzzle(id: "used", rating: 500),
            makePuzzle(id: "unused", rating: 525)
        ]
        let (sut, _) = makeSUT(pool: pool, activeUsedIDs: ["used"])

        XCTAssertEqual(sut.currentPuzzle?.id, "unused")
    }

    func test_loadNextPuzzle_multipleCorrectMoves_usesUniquePuzzles() {
        let pool = (1...20).map { makePuzzle(id: "\($0)", rating: 500 + ($0 * 50)) }
        let (sut, _) = makeSUT(pool: pool)

        var seenIDs = Set<String>()
        if let first = sut.currentPuzzle { seenIDs.insert(first.id) }

        for _ in 0..<5 {
            sut.handlePuzzleCompletion(isCorrect: true)
            if let puzzle = sut.currentPuzzle {
                seenIDs.insert(puzzle.id)
            }
        }

        XCTAssertGreaterThan(seenIDs.count, 1, "Expected multiple unique puzzles to be used across streaks")
    }

    // MARK: - Full Session Flow

    func test_fullSession_correctThenIncorrect_thenNextTapped() {
        let (sut, spy) = makeSUT(highestStreak: 0)

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentStreak, 3)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertTrue(sut.isPuzzleFinished)
        XCTAssertTrue(sut.isNewRecord)
        XCTAssertEqual(spy.sessionFinishedScores, [3])

        sut.onNextTapped()

        XCTAssertEqual(sut.currentStreak, 0)
        XCTAssertEqual(sut.currentHighestStreak, 3)
        XCTAssertFalse(sut.isPuzzleFinished)
        XCTAssertFalse(sut.isNewRecord)
    }

    // MARK: - Helpers

    private let defaultPool: [Puzzle] = {
        (1...20).map { i in
            let rating = 400 + (i * 50)
            return Puzzle(id: "\(i)", fen: "fen\(i)", moves: ["e4"], rating: rating, tags: [])
        }
    }()

    private func makeSUT(
        pool: [Puzzle]? = nil,
        activeStreak: Int = 0,
        activeUsedIDs: Set<String> = [],
        highestStreak: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleStreakViewModel, spy: DelegateSpy) {

        let puzzles = pool ?? defaultPool
        let spy = DelegateSpy()

        let sut = PuzzleStreakViewModel(
            pool: puzzles,
            activeStreak: activeStreak,
            activeUsedIDs: activeUsedIDs,
            highestStreak: highestStreak,
            onStreakUpdated: { streak, ids in
                spy.streakUpdates.append((streak: streak, usedIDs: ids))
            },
            onSessionFinished: { score in
                spy.sessionFinishedScores.append(score)
            },
            updateDailyLimits: { count, date in
                spy.limitUpdates.append((count, date))
            },
            onPuzzleSolved: {
                spy.puzzleSolvedCount += 1
            }
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)

        return (sut, spy)
    }

    private func makePuzzle(id: String, rating: Int) -> Puzzle {
        return Puzzle(id: id, fen: "any", moves: [], rating: rating, tags: [])
    }

    private class DelegateSpy {
        var streakUpdates = [(streak: Int, usedIDs: Set<String>)]()
        var sessionFinishedScores = [Int]()
        var limitUpdates = [(Int, Date)]()
        var puzzleSolvedCount = 0
    }
}
