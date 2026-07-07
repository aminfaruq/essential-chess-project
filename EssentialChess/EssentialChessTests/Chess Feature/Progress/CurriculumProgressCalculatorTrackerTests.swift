//
//  CurriculumProgressTrackerTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class CurriculumProgressCalculatorTrackerTests: XCTestCase {
    
    // MARK: - Section Unlock Logic
    
    func test_isSectionUnlocked_returnsTrueIfSectionIsNotLockedByDefault() {
        let section = makeSection(isLocked: false, eloRange: "0-500")
        let progress = UserProgress(hiddenRating: 100)
        XCTAssertTrue(CurriculumProgressCalculator.isSectionUnlocked(section, progress: progress))
    }
    
    func test_isSectionUnlocked_returnsFalseIfRatingIsBelowFloor() {
        let section = makeSection(isLocked: true, eloRange: "1200-1600")
        let progress = UserProgress(hiddenRating: 1199.9)
        
        XCTAssertFalse(CurriculumProgressCalculator.isSectionUnlocked(section, progress: progress))
    }
    
    func test_isSectionUnlocked_returnsTrueIfRatingMeetsOrExceedsFloor() {
        let section = makeSection(isLocked: true, eloRange: "1200-1600")
        
        let exactProgress = UserProgress(hiddenRating: 1200.0)
        XCTAssertTrue(CurriculumProgressCalculator.isSectionUnlocked(section, progress: exactProgress))
        
        let higherProgress = UserProgress(hiddenRating: 1500.0)
        XCTAssertTrue(CurriculumProgressCalculator.isSectionUnlocked(section, progress: higherProgress))
    }
    
    // MARK: - SubTheme Progress Logic
    
    func test_progressForSubTheme_returnsZeroWhenTotalPuzzlesIsZero() {
        let subTheme = makeSubTheme(totalPuzzles: 0, puzzleIDs: [])
        let progress = UserProgress(completedPuzzleIDs: ["p1"])
        
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: subTheme, progress: progress), 0.0)
    }
    
    func test_progressForSubTheme_calculatesCorrectPercentage() {
        // SubTheme has 4 puzzles
        let subTheme = makeSubTheme(totalPuzzles: 4, puzzleIDs: ["p1", "p2", "p3", "p4"])
        
        // User has completed 1 out of 4 (25%)
        let progress1 = UserProgress(completedPuzzleIDs: ["p1", "other_puzzle"])
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: subTheme, progress: progress1), 0.25)
        
        // User has completed 4 out of 4 (100%)
        let progress2 = UserProgress(completedPuzzleIDs: ["p1", "p2", "p3", "p4"])
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: subTheme, progress: progress2), 1.0)
    }
    
    // MARK: - Category Progress Logic
    
    func test_progressForCategory_returnsZeroIfNoSubThemes() {
        let category = makeCategory(isExam: false, subThemes: [])
        let progress = UserProgress()
        
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: category, progress: progress), 0.0)
    }
    
    func test_progressForCategory_calculatesCombinedSubThemeProgress() {
        let sub1 = makeSubTheme(totalPuzzles: 2, puzzleIDs: ["p1", "p2"])
        let sub2 = makeSubTheme(totalPuzzles: 2, puzzleIDs: ["p3", "p4"])
        let category = makeCategory(isExam: false, subThemes: [sub1, sub2])
        
        let progress = UserProgress(completedPuzzleIDs: ["p1", "p3", "p4"]) // 3 out of 4 (75%)
        
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: category, progress: progress), 0.75)
    }
    
    // MARK: - Section Progress Logic
    
    func test_progressForSection_returnsOneIfExamPassed() {
        let examCategory = makeCategory(id: "exam_cat", isExam: true, subThemes: [])
        let section = EloSection(id: "s1", title: "any", eloRange: "0-500", isLockedByDefault: false, categories: [examCategory])
        
        let progress = UserProgress(passedExamIDs: ["exam_cat"]) // Exam passed!
        
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: section, progress: progress), 1.0)
    }
    
    func test_progressForSection_capsAt99PercentIfExamNotPassed() {
        let sub = makeSubTheme(totalPuzzles: 2, puzzleIDs: ["p1", "p2"])
        let nonExamCat = makeCategory(id: "c1", isExam: false, subThemes: [sub])
        let section = EloSection(id: "s1", title: "any", eloRange: "0-500", isLockedByDefault: false, categories: [nonExamCat])
        
        let progress = UserProgress(completedPuzzleIDs: ["p1", "p2"]) // 100% of puzzles done
        
        // Because exam is not passed, it should cap at 0.99
        XCTAssertEqual(CurriculumProgressCalculator.progress(for: section, progress: progress), 0.99)
    }
    
    func test_isExamUnlocked_returnsTrueOnlyWhenAllNonExamPuzzlesAreCompleted() {
        let sub = makeSubTheme(totalPuzzles: 2, puzzleIDs: ["p1", "p2"])
        let nonExamCat = makeCategory(id: "c1", isExam: false, subThemes: [sub])
        let section = EloSection(id: "s1", title: "any", eloRange: "0-500", isLockedByDefault: false, categories: [nonExamCat])
        
        let incompleteProgress = UserProgress(completedPuzzleIDs: ["p1"])
        XCTAssertFalse(CurriculumProgressCalculator.isExamUnlocked(for: section, progress: incompleteProgress))
        
        let completeProgress = UserProgress(completedPuzzleIDs: ["p1", "p2"])
        XCTAssertTrue(CurriculumProgressCalculator.isExamUnlocked(for: section, progress: completeProgress))
    }
    
    // MARK: - Exam Cooldown Logic
    
    func test_canStartExam_returnsTrueIfNoFailureRecorded() {
        let progress = UserProgress(examFailureTimes: [:])
        XCTAssertTrue(CurriculumProgressCalculator.canStartExam(categoryID: "exam1", progress: progress, currentDate: Date()))
    }
    
    func test_canStartExam_enforcesThreeHourCooldown() {
        let failureDate = Date()
        let progress = UserProgress(examFailureTimes: ["exam1": failureDate])
        
        // 2 hours later -> Cannot start
        let twoHoursLater = failureDate.addingTimeInterval(2 * 3600)
        XCTAssertFalse(CurriculumProgressCalculator.canStartExam(categoryID: "exam1", progress: progress, currentDate: twoHoursLater))
        
        // 3 hours later -> Can start
        let threeHoursLater = failureDate.addingTimeInterval(3 * 3600)
        XCTAssertTrue(CurriculumProgressCalculator.canStartExam(categoryID: "exam1", progress: progress, currentDate: threeHoursLater))
    }
    
    func test_remainingCooldown_returnsCorrectTimeInterval() {
        let failureDate = Date()
        let progress = UserProgress(examFailureTimes: ["exam1": failureDate])
        
        // 1 hour has passed, 2 hours (7200 seconds) remaining
        let oneHourLater = failureDate.addingTimeInterval(3600)
        XCTAssertEqual(CurriculumProgressCalculator.remainingCooldown(categoryID: "exam1", progress: progress, currentDate: oneHourLater), 7200)
        
        // 4 hours have passed, 0 remaining
        let fourHoursLater = failureDate.addingTimeInterval(4 * 3600)
        XCTAssertEqual(CurriculumProgressCalculator.remainingCooldown(categoryID: "exam1", progress: progress, currentDate: fourHoursLater), 0)
    }
    
    // MARK: - Helpers
    
    private func makeCategory(id: String = "any_id", isExam: Bool, subThemes: [SubTheme]) -> EssentialChess.Category {
        return Category(id: id, title: "any", isExamMode: isExam, description: nil, totalPuzzles: nil, puzzles: nil, subThemes: subThemes)
    }
    
    private func makeSection(isLocked: Bool, eloRange: String) -> EloSection {
        return EloSection(id: "any", title: "any", eloRange: eloRange, isLockedByDefault: isLocked, categories: [])
    }
    
    private func makeSubTheme(totalPuzzles: Int, puzzleIDs: [String]) -> SubTheme {
        let puzzles = puzzleIDs.map { Puzzle(id: $0, fen: "", moves: [], rating: 1000, tags: []) }
        return SubTheme(id: "any", title: "any", totalPuzzles: totalPuzzles, puzzles: puzzles)
    }
}
