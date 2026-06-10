//
//  CurriculumProgressTrackerTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class CurriculumProgressTrackerTests: XCTestCase {
    
    // MARK: - Section Unlock Logic
    
    func test_isSectionUnlocked_returnsTrueIfSectionIsNotLockedByDefault() {
        let section = makeSection(isLocked: false, eloRange: "0-500")
        let progress = UserProgress(hiddenRating: 100)
        XCTAssertTrue(CurriculumProgressTracker.isSectionUnlocked(section, progress: progress))
    }
    
    func test_isSectionUnlocked_returnsFalseIfRatingIsBelowFloor() {
        let section = makeSection(isLocked: true, eloRange: "1200-1600")
        let progress = UserProgress(hiddenRating: 1199.9)
        
        XCTAssertFalse(CurriculumProgressTracker.isSectionUnlocked(section, progress: progress))
    }
    
    func test_isSectionUnlocked_returnsTrueIfRatingMeetsOrExceedsFloor() {
        let section = makeSection(isLocked: true, eloRange: "1200-1600")
        
        let exactProgress = UserProgress(hiddenRating: 1200.0)
        XCTAssertTrue(CurriculumProgressTracker.isSectionUnlocked(section, progress: exactProgress))
        
        let higherProgress = UserProgress(hiddenRating: 1500.0)
        XCTAssertTrue(CurriculumProgressTracker.isSectionUnlocked(section, progress: higherProgress))
    }
    
    // MARK: - SubTheme Progress Logic
    
    func test_progressForSubTheme_returnsZeroWhenTotalPuzzlesIsZero() {
        let subTheme = makeSubTheme(totalPuzzles: 0, puzzleIDs: [])
        let progress = UserProgress(completedPuzzleIDs: ["p1"])
        
        XCTAssertEqual(CurriculumProgressTracker.progress(for: subTheme, progress: progress), 0.0)
    }
    
    func test_progressForSubTheme_calculatesCorrectPercentage() {
        // SubTheme has 4 puzzles
        let subTheme = makeSubTheme(totalPuzzles: 4, puzzleIDs: ["p1", "p2", "p3", "p4"])
        
        // User has completed 1 out of 4 (25%)
        let progress1 = UserProgress(completedPuzzleIDs: ["p1", "other_puzzle"])
        XCTAssertEqual(CurriculumProgressTracker.progress(for: subTheme, progress: progress1), 0.25)
        
        // User has completed 4 out of 4 (100%)
        let progress2 = UserProgress(completedPuzzleIDs: ["p1", "p2", "p3", "p4"])
        XCTAssertEqual(CurriculumProgressTracker.progress(for: subTheme, progress: progress2), 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSection(isLocked: Bool, eloRange: String) -> EloSection {
        return EloSection(id: "any", title: "any", eloRange: eloRange, isLockedByDefault: isLocked, categories: [])
    }
    
    private func makeSubTheme(totalPuzzles: Int, puzzleIDs: [String]) -> SubTheme {
        let puzzles = puzzleIDs.map { Puzzle(id: $0, fen: "", moves: [], rating: 1000, tags: []) }
        return SubTheme(id: "any", title: "any", totalPuzzles: totalPuzzles, puzzles: puzzles)
    }
}
