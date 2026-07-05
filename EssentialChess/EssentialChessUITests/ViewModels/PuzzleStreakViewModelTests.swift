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

    // MARK: - Scenario: Starting a free Puzzle Streak session
    
    func test_init_startsFreeSession_deductsQuotaAndLoadsBaselinePuzzle() {
        let pool = [
            makePuzzle(id: "1", rating: 400),
            makePuzzle(id: "2", rating: 500),
            makePuzzle(id: "3", rating: 600)
        ]
        var updatedCount: Int?
        var updatedDate: Date?
        
        let sut = makeSUT(
            pool: pool,
            checkIsPro: { false },
            dailyPuzzleStreakCount: 0,
            lastPuzzleStreakDate: nil,
            updateDailyLimits: { count, date in
                updatedCount = count
                updatedDate = date
            }
        )
        
        XCTAssertEqual(updatedCount, 1, "Expected daily quota to be deducted (incremented to 1)")
        XCTAssertNotNil(updatedDate, "Expected session timestamp to be recorded")
        XCTAssertEqual(sut.currentStreak, 0, "Expected streak score initialized to 0")
        
        // Target rating for streak 0 is 500, range 400...600.
        let loadedRating = sut.currentPuzzle?.rating ?? 0
        XCTAssertTrue((400...600).contains(loadedRating), "Expected baseline difficulty puzzle (~500 Elo +/- 100) to be presented")
        XCTAssertFalse(sut.isDailyLimitReached, "Expected daily limit not to be reached yet")
    }

    // MARK: - Scenario: Successfully solving a puzzle and scaling difficulty
    
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

    // MARK: - Scenario: Failing a puzzle on the Free tier
    
    func test_handlePuzzleCompletion_incorrectMoveOnFreeTier_terminatesSessionAndShowsPaywall() {
        let pool = [makePuzzle(id: "1", rating: 500)]
        var finishedStreak: Int?
        
        let sut = makeSUT(
            pool: pool,
            checkIsPro: { false },
            onSessionFinished: { streak in
                finishedStreak = streak
            }
        )
        
        sut.handlePuzzleCompletion(isCorrect: false)
        
        XCTAssertTrue(sut.isPuzzleFinished, "Expected session to immediately terminate")
        XCTAssertTrue(sut.hasFailed, "Expected failure state to be active")
        XCTAssertTrue(sut.showCorrectMove, "Expected correct move to be shown")
        XCTAssertEqual(finishedStreak, 0, "Expected final streak score to be recorded")
        
        // In the new logic, the paywall is not shown immediately on failure.
        // It is shown when the user taps "Try Again" (onNextTapped) on the result screen.
        XCTAssertFalse(sut.showPaywall, "Expected paywall NOT to be displayed immediately on fail")
        
        // Simulating the user tapping "Try Again"
        sut.onNextTapped()
        XCTAssertTrue(sut.showPaywall, "Expected paywall prompt to be displayed for upgrade after trying again")
    }

    // MARK: - Scenario: Attempting to play when daily free quota is exhausted
    
    func test_init_dailyQuotaExhaustedOnFreeTier_deniesAccessAndShowsPaywall() {
        let sut = makeSUT(
            checkIsPro: { false },
            dailyPuzzleStreakCount: 1, // Already used today
            lastPuzzleStreakDate: Date() // Today
        )
        
        XCTAssertTrue(sut.isDailyLimitReached, "Expected daily limit to be flagged as reached")
        XCTAssertTrue(sut.showPaywall, "Expected paywall screen to be presented immediately")
        XCTAssertNil(sut.currentPuzzle, "Expected access to the game mode to be denied (no puzzle loaded)")
    }

    // MARK: - Scenario: Unlimited access for Pro users
    
    func test_handlePuzzleCompletion_incorrectMoveOnProTier_displaysScoreButNoPaywall() {
        var finishedStreak: Int?
        let sut = makeSUT(
            checkIsPro: { true },
            onSessionFinished: { streak in
                finishedStreak = streak
            }
        )
        
        sut.handlePuzzleCompletion(isCorrect: false)
        
        XCTAssertTrue(sut.isPuzzleFinished, "Expected session to terminate")
        XCTAssertTrue(sut.hasFailed, "Expected failure state to be active")
        XCTAssertEqual(finishedStreak, 0, "Expected final streak score to be recorded")
        XCTAssertFalse(sut.showPaywall, "Expected NO paywall prompt for Pro user")
    }
    
    func test_onNextTapped_proUserCanStartNewSessionWithoutLimits() {
        let sut = makeSUT(
            checkIsPro: { true },
            dailyPuzzleStreakCount: 5, // Arbitrary high count
            lastPuzzleStreakDate: Date() // Today
        )
        
        // Even with high usage today, Pro user should be allowed
        sut.onNextTapped()
        
        XCTAssertFalse(sut.isDailyLimitReached, "Expected daily limit check to pass for Pro users")
        XCTAssertNotNil(sut.currentPuzzle, "Expected new puzzle session to start")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        pool: [Puzzle]? = nil,
        checkIsPro: @escaping () -> Bool = { false },
        dailyPuzzleStreakCount: Int = 0,
        lastPuzzleStreakDate: Date? = nil,
        activeStreak: Int = 0,
        activeUsedIDs: Set<String> = [],
        highestStreak: Int = 0,
        onStreakUpdated: @escaping (Int, Set<String>) -> Void = { _, _ in },
        onSessionFinished: @escaping (Int) -> Void = { _ in },
        updateDailyLimits: @escaping (Int, Date) -> Void = { _, _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> PuzzleStreakViewModel {
        
        let puzzles = pool ?? [makePuzzle(id: "default", rating: 500)]
        
        let sut = PuzzleStreakViewModel(
            pool: puzzles,
            checkIsPro: checkIsPro,
            dailyPuzzleStreakCount: dailyPuzzleStreakCount,
            lastPuzzleStreakDate: lastPuzzleStreakDate,
            activeStreak: activeStreak,
            activeUsedIDs: activeUsedIDs,
            highestStreak: highestStreak,
            onStreakUpdated: onStreakUpdated,
            onSessionFinished: onSessionFinished,
            updateDailyLimits: updateDailyLimits, onPuzzleSolved: {}
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func makePuzzle(id: String, rating: Int) -> Puzzle {
        return Puzzle(id: id, fen: "any", moves: [], rating: rating, tags: [])
    }
}
