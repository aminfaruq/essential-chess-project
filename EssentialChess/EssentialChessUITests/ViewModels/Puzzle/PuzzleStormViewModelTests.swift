//
//  PuzzleStormViewModelTests.swift
//  EssentialChess
//
//  Created by App on 21/06/26.
//

import XCTest
import Combine
import EssentialChess
import EssentialChessUI

final class PuzzleStormViewModelTests: XCTestCase {

    // MARK: - Init Tests

    func test_init_doesNotStartGame() {
        let (sut, _) = makeSUT()

        XCTAssertFalse(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.timeRemaining, 180)
        XCTAssertEqual(sut.currentScore, 0)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertNil(sut.currentPuzzle)
    }

    func test_init_setsCurrentHighestScore() {
        let (sut, _) = makeSUT(highestScore: 42)

        XCTAssertEqual(sut.currentHighestScore, 42)
    }

    func test_init_doesNotSetNewRecordInitially() {
        let (sut, _) = makeSUT()

        XCTAssertFalse(sut.isNewRecord)
    }

    // MARK: - onStartTapped Tests

    func test_onStartTapped_startsGameAndLoadsFirstPuzzle() {
        let (sut, _) = makeSUT()

        sut.onStartTapped()

        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.timeRemaining, 180)
        XCTAssertNotNil(sut.currentPuzzle)
    }

    func test_onStartTapped_restartsActiveGame() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, 2)
        XCTAssertEqual(sut.currentCombo, 2)

        sut.onStartTapped()

        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.currentScore, 0)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertEqual(sut.highestCombo, 0)
        XCTAssertEqual(sut.timeRemaining, 180)
        XCTAssertFalse(sut.isNewRecord)
        XCTAssertNotNil(sut.currentPuzzle)
    }

    func test_onStartTapped_restartsAfterGameOver() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        drainGame(sut)

        XCTAssertTrue(sut.isGameOver)

        sut.onStartTapped()

        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.currentScore, 0)
        XCTAssertNotNil(sut.currentPuzzle)
    }

    // MARK: - handlePuzzleCompletion Guard Tests

    func test_handlePuzzleCompletion_beforeStart_doesNothing() {
        let (sut, spy) = makeSUT()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertFalse(sut.isGameActive)
        XCTAssertEqual(sut.currentScore, 0)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertEqual(spy.puzzleSolvedCount, 0)
    }

    func test_handlePuzzleCompletion_afterGameOver_doesNothing() {
        let (sut, spy) = makeSUT()
        sut.onStartTapped()
        drainGame(sut)
        let finalScore = sut.currentScore
        spy.puzzleSolvedCount = 0

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, finalScore, "Score should not change after game over")
        XCTAssertEqual(spy.puzzleSolvedCount, 0)
    }

    // MARK: - handlePuzzleCompletion Correct Tests

    func test_handlePuzzleCompletion_correctIncreasesScoreAndCombo() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        let initialPuzzle = sut.currentPuzzle

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, 1)
        XCTAssertEqual(sut.currentCombo, 1)
        XCTAssertEqual(sut.highestCombo, 1)
        XCTAssertNotEqual(sut.currentPuzzle?.id, initialPuzzle?.id)
    }

    func test_handlePuzzleCompletion_correct_callsOnPuzzleSolved() {
        let (sut, spy) = makeSUT()
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(spy.puzzleSolvedCount, 1)
    }

    func test_handlePuzzleCompletion_correct_tracksHighestCombo() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.highestCombo, 3)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertEqual(sut.highestCombo, 3, "Highest combo should persist after mistake")

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentCombo, 1)
        XCTAssertEqual(sut.highestCombo, 3, "Highest combo should not drop below previous peak")
    }

    // MARK: - handlePuzzleCompletion Incorrect Tests

    func test_handlePuzzleCompletion_incorrectResetsComboAndAppliesPenalty() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, 2)
        XCTAssertEqual(sut.currentCombo, 2)
        XCTAssertEqual(sut.timeRemaining, 180)

        let puzzleBeforeMistake = sut.currentPuzzle

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(sut.currentScore, 2)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertEqual(sut.timeRemaining, 170)
        XCTAssertTrue(sut.showPenaltyIndicator)
        XCTAssertNotEqual(sut.currentPuzzle?.id, puzzleBeforeMistake?.id)
        XCTAssertTrue(sut.isGameActive)
    }

    func test_handlePuzzleCompletion_mistakeEndsGameIfTimerHitsZero() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        for _ in 0..<18 {
            sut.handlePuzzleCompletion(isCorrect: false)
        }

        XCTAssertEqual(sut.timeRemaining, 0)
        XCTAssertFalse(sut.isGameActive)
        XCTAssertTrue(sut.isGameOver)
    }

    func test_handlePuzzleCompletion_mistakeClampsTimerToZero() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: false)
        let remaining = sut.timeRemaining
        for _ in 0..<(remaining / 10) {
            sut.handlePuzzleCompletion(isCorrect: false)
        }

        XCTAssertEqual(sut.timeRemaining, 0, "Timer should be clamped to 0, not negative")
    }

    // MARK: - Combo Bonus Tests

    func test_comboBonus_addsTimeAtThreshold5() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        for _ in 0..<4 {
            sut.handlePuzzleCompletion(isCorrect: true)
        }

        XCTAssertEqual(sut.timeRemaining, 180)

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.timeRemaining, 183)
        XCTAssertTrue(sut.showBonusIndicator)
        XCTAssertEqual(sut.lastBonusAmount, 3)
    }

    func test_comboBonus_addsTimeAtThreshold12() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        for _ in 0..<12 {
            sut.handlePuzzleCompletion(isCorrect: true)
        }

        XCTAssertEqual(sut.currentCombo, 12)
        XCTAssertEqual(sut.timeRemaining, 187, "Expected 180 + 3 (combo 5) + 4 (combo 12)")
        XCTAssertTrue(sut.showBonusIndicator)
        XCTAssertEqual(sut.lastBonusAmount, 4)
    }

    func test_noComboBonus_atNonThresholds() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        for _ in 0..<3 {
            sut.handlePuzzleCompletion(isCorrect: true)
        }

        XCTAssertEqual(sut.currentCombo, 3)
        XCTAssertEqual(sut.timeRemaining, 180)
    }

    func test_comboBonus_atThreshold100_adds15Seconds() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()

        for _ in 0..<100 {
            sut.handlePuzzleCompletion(isCorrect: true)
        }

        XCTAssertEqual(sut.currentCombo, 100)
        XCTAssertTrue(sut.showBonusIndicator)
        XCTAssertEqual(sut.lastBonusAmount, 15)
    }

    // MARK: - endGame Tests (via drain)

    func test_endGame_setsGameOverState() {
        let (sut, spy) = makeSUT()
        sut.onStartTapped()
        drainGame(sut)

        XCTAssertFalse(sut.isGameActive)
        XCTAssertTrue(sut.isGameOver)
        XCTAssertNil(sut.currentPuzzle)
        XCTAssertNotEqual(spy.sessionFinishedScores.count, 0)
    }

    func test_endGame_setsNewRecordWhenScoreExceedsHighest() {
        let (sut, _) = makeSUT(highestScore: 1)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertTrue(sut.isNewRecord)
        XCTAssertEqual(sut.currentHighestScore, 3)
    }

    func test_endGame_doesNotSetNewRecordWhenScoreEqualsHighest() {
        let (sut, _) = makeSUT(highestScore: 2)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertFalse(sut.isNewRecord)
        XCTAssertEqual(sut.currentHighestScore, 2)
    }

    func test_endGame_doesNotSetNewRecordWhenScoreBelowHighest() {
        let (sut, _) = makeSUT(highestScore: 10)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertFalse(sut.isNewRecord)
        XCTAssertEqual(sut.currentHighestScore, 10)
    }

    func test_endGame_callsOnScoreUpdatedOnNewRecord() {
        let (sut, spy) = makeSUT(highestScore: 0)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertEqual(spy.scoreUpdates, [2])
    }

    func test_endGame_doesNotCallOnScoreUpdatedWhenNotRecord() {
        let (sut, spy) = makeSUT(highestScore: 100)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertEqual(spy.scoreUpdates, [])
    }

    func test_endGame_callsOnSessionFinished() {
        let (sut, spy) = makeSUT()
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)
        drainGame(sut)

        XCTAssertEqual(spy.sessionFinishedScores, [2])
    }

    // MARK: - loadNextPuzzle Edge Cases

    func test_loadNextPuzzle_filtersOutUsedPuzzles() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        let firstId = sut.currentPuzzle?.id

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertNotEqual(sut.currentPuzzle?.id, firstId, "Should load a different puzzle")
    }

    func test_loadNextPuzzle_whenPoolExhausted_resetsAndReuses() {
        let smallPool = [
            Puzzle(id: "a", fen: "a", moves: [], rating: 300, tags: []),
            Puzzle(id: "b", fen: "b", moves: [], rating: 400, tags: [])
        ]
        let spy = DelegateSpy()
        let sut = PuzzleStormViewModel(
            pool: smallPool,
            highestScore: 0,
            onScoreUpdated: { spy.scoreUpdates.append($0) },
            onSessionFinished: { spy.sessionFinishedScores.append($0) },
            updateDailyLimits: { count, date in spy.limitUpdates.append((count, date)) },
            onPuzzleSolved: { spy.puzzleSolvedCount += 1 }
        )
        sut.onStartTapped()
        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, 3, "Game should continue after pool exhausted and reset")
        XCTAssertNotNil(sut.currentPuzzle)
    }

    // MARK: - Full Session Flow

    func test_fullSession_startCorrectCorrectMistakeEndGame() {
        let (sut, spy) = makeSUT(highestScore: 0)
        sut.onStartTapped()

        sut.handlePuzzleCompletion(isCorrect: true)
        sut.handlePuzzleCompletion(isCorrect: true)

        XCTAssertEqual(sut.currentScore, 2)
        XCTAssertEqual(sut.currentCombo, 2)

        sut.handlePuzzleCompletion(isCorrect: false)

        XCTAssertEqual(sut.currentScore, 2)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertTrue(sut.showPenaltyIndicator)

        drainGame(sut)

        XCTAssertTrue(sut.isGameOver)
        XCTAssertTrue(sut.isNewRecord)
        XCTAssertEqual(sut.currentHighestScore, 2)
        XCTAssertEqual(spy.scoreUpdates, [2])
        XCTAssertEqual(spy.sessionFinishedScores, [2])
    }

    // MARK: - Helpers

    private func makeSUT(
        highestScore: Int = 0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: PuzzleStormViewModel, spy: DelegateSpy) {
        let pool = [
            Puzzle(id: "1", fen: "1", moves: ["e4"], rating: 300, tags: []),
            Puzzle(id: "2", fen: "2", moves: ["d4"], rating: 350, tags: []),
            Puzzle(id: "3", fen: "3", moves: ["c4"], rating: 400, tags: []),
            Puzzle(id: "4", fen: "4", moves: ["Nf3"], rating: 450, tags: []),
            Puzzle(id: "5", fen: "5", moves: ["g3"], rating: 500, tags: []),
            Puzzle(id: "6", fen: "6", moves: ["f4"], rating: 550, tags: []),
            Puzzle(id: "7", fen: "7", moves: ["b3"], rating: 600, tags: []),
            Puzzle(id: "8", fen: "8", moves: ["e3"], rating: 650, tags: []),
            Puzzle(id: "9", fen: "9", moves: ["a3"], rating: 700, tags: []),
            Puzzle(id: "10", fen: "10", moves: ["h3"], rating: 750, tags: []),
            Puzzle(id: "11", fen: "11", moves: ["e4"], rating: 800, tags: []),
            Puzzle(id: "12", fen: "12", moves: ["d4"], rating: 850, tags: []),
            Puzzle(id: "13", fen: "13", moves: ["c4"], rating: 900, tags: []),
            Puzzle(id: "14", fen: "14", moves: ["Nf3"], rating: 950, tags: []),
            Puzzle(id: "15", fen: "15", moves: ["g3"], rating: 1000, tags: []),
            Puzzle(id: "16", fen: "16", moves: ["f4"], rating: 1050, tags: []),
            Puzzle(id: "17", fen: "17", moves: ["b3"], rating: 1100, tags: []),
            Puzzle(id: "18", fen: "18", moves: ["e3"], rating: 1150, tags: []),
            Puzzle(id: "19", fen: "19", moves: ["a3"], rating: 1200, tags: []),
            Puzzle(id: "20", fen: "20", moves: ["h3"], rating: 1250, tags: []),
            Puzzle(id: "21", fen: "21", moves: ["h3"], rating: 1300, tags: [])
        ]

        let spy = DelegateSpy()
        let sut = PuzzleStormViewModel(
            pool: pool,
            highestScore: highestScore,
            onScoreUpdated: { spy.scoreUpdates.append($0) },
            onSessionFinished: { spy.sessionFinishedScores.append($0) },
            updateDailyLimits: { count, date in spy.limitUpdates.append((count, date)) },
            onPuzzleSolved: { spy.puzzleSolvedCount += 1 }
        )

        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(spy, file: file, line: line)

        return (sut, spy)
    }

    private func drainGame(_ sut: PuzzleStormViewModel) {
        while sut.isGameActive {
            sut.handlePuzzleCompletion(isCorrect: false)
        }
    }

    private class DelegateSpy {
        var scoreUpdates = [Int]()
        var sessionFinishedScores = [Int]()
        var limitUpdates = [(Int, Date)]()
        var puzzleSolvedCount = 0
    }
}
