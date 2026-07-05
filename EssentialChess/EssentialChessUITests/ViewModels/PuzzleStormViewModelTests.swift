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
    
    func test_init_doesNotStartGame() {
        let (sut, _) = makeSUT()
        
        XCTAssertFalse(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.timeRemaining, 180)
        XCTAssertEqual(sut.currentScore, 0)
        XCTAssertEqual(sut.currentCombo, 0)
        XCTAssertNil(sut.currentPuzzle)
    }
    
    func test_onStartTapped_startsGameAndLoadsFirstPuzzle() {
        let (sut, _) = makeSUT()
        
        sut.onStartTapped()
        
        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.isGameOver)
        XCTAssertEqual(sut.timeRemaining, 180)
        XCTAssertNotNil(sut.currentPuzzle)
    }
    
    func test_handlePuzzleCompletion_correctIncreasesScoreAndCombo() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        let initialScore = sut.currentScore
        let initialCombo = sut.currentCombo
        let initialPuzzle = sut.currentPuzzle
        
        sut.handlePuzzleCompletion(isCorrect: true)
        
        XCTAssertEqual(sut.currentScore, initialScore + 1)
        XCTAssertEqual(sut.currentCombo, initialCombo + 1)
        XCTAssertEqual(sut.highestCombo, initialCombo + 1)
        XCTAssertNotEqual(sut.currentPuzzle?.id, initialPuzzle?.id)
    }
    
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
        
        // Fast forward timer or artificially reduce it to 5 seconds
        // Instead of waiting, we can simulate by calling mistake multiple times
        for _ in 0..<18 {
            sut.handlePuzzleCompletion(isCorrect: false)
        }
        
        XCTAssertEqual(sut.timeRemaining, 0)
        XCTAssertFalse(sut.isGameActive)
        XCTAssertTrue(sut.isGameOver)
    }
    
    func test_comboBonus_addsTimeAtThresholds() {
        let (sut, _) = makeSUT()
        sut.onStartTapped()
        
        // Solve 4 puzzles
        for _ in 0..<4 {
            sut.handlePuzzleCompletion(isCorrect: true)
        }
        
        XCTAssertEqual(sut.timeRemaining, 180)
        
        // 5th puzzle hits threshold (+3s)
        sut.handlePuzzleCompletion(isCorrect: true)
        
        XCTAssertEqual(sut.timeRemaining, 183)
        XCTAssertTrue(sut.showBonusIndicator)
        XCTAssertEqual(sut.lastBonusAmount, 3)
    }
    
    func test_dailyLimit_preventsStartingForFreeUserWhenLimitReached() {
        let (sut, _) = makeSUT(isPro: false, dailyCount: 1, lastDate: Date())
        
        sut.onStartTapped()
        
        XCTAssertFalse(sut.isGameActive)
        XCTAssertTrue(sut.showPaywall)
        XCTAssertTrue(sut.isDailyLimitReached)
    }
    
    func test_dailyLimit_allowsStartingForFreeUserOnNewDay() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let (sut, _) = makeSUT(isPro: false, dailyCount: 1, lastDate: yesterday)
        
        sut.onStartTapped()
        
        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.showPaywall)
        XCTAssertFalse(sut.isDailyLimitReached)
    }
    
    func test_dailyLimit_allowsStartingForProUserEvenWhenLimitReached() {
        let (sut, _) = makeSUT(isPro: true, dailyCount: 5, lastDate: Date())
        
        sut.onStartTapped()
        
        XCTAssertTrue(sut.isGameActive)
        XCTAssertFalse(sut.showPaywall)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        isPro: Bool = true,
        dailyCount: Int = 0,
        lastDate: Date? = nil,
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
            checkIsPro: { isPro },
            dailyPuzzleStormCount: dailyCount,
            lastPuzzleStormDate: lastDate,
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
    
    private class DelegateSpy {
        var scoreUpdates = [Int]()
        var sessionFinishedScores = [Int]()
        var limitUpdates = [(Int, Date)]()
        var puzzleSolvedCount = 0
    }
}
