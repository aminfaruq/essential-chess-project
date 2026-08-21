//
//  UserProgressUpdaterTests.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import XCTest
import EssentialChess

final class UserProgressUpdaterTests: XCTestCase {

    func test_completeOnboarding_updatesRatingAndFlag() {
        let initial = UserProgress(hiddenRating: 500, onboardingComplete: false)
        
        let updated = UserProgressUpdater.completeOnboarding(progress: initial, newRating: 1200)
        
        XCTAssertEqual(updated.hiddenRating, 1200)
        XCTAssertTrue(updated.onboardingComplete)
    }
    
    func test_markPuzzleCompleted_addsIDToSet() {
        let initial = UserProgress(completedPuzzleIDs: ["p1"])
        
        let updated = UserProgressUpdater.markPuzzleCompleted("p2", progress: initial)
        
        XCTAssertEqual(updated.completedPuzzleIDs, ["p1", "p2"])
    }
    
    func test_markExamPassed_addsIDUpdatesRatingAndClearsFailureTime() {
        let initial = UserProgress(
            hiddenRating: 800,
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()] // Sebelumnya pernah gagal di e2
        )
        
        let updated = UserProgressUpdater.markExamPassed(categoryID: "e2", nextSectionFloor: 1200, progress: initial)
        
        XCTAssertEqual(updated.passedExamIDs, ["e1", "e2"])
        XCTAssertEqual(updated.hiddenRating, 1200)
        XCTAssertNil(updated.examFailureTimes["e2"], "Expected failure time for passed exam to be cleared")
    }
    
    func test_registerExamFailure_setsFailureTime() {
        let initial = UserProgress(examFailureTimes: [:])
        let failureDate = Date()
        
        let updated = UserProgressUpdater.registerExamFailure(categoryID: "e1", progress: initial, currentDate: failureDate)
        
        XCTAssertEqual(updated.examFailureTimes["e1"], failureDate)
    }
    
    func test_mutations_preserveActualRatingAndOtherExtendedFields() {
        let initial = UserProgress(
            hiddenRating: 1000,
            actualRating: 2000,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()],
            currentStreak: 7,
            lastActivityDate: Date(),
            unlockedFeatures: [.openingStudy],
            dailyPuzzleMixCount: 10,
            lastPuzzleMixDate: Date(),
            dailyPuzzleStreakCount: 5,
            lastPuzzleStreakDate: Date(),
            activePuzzleStreak: 3,
            activePuzzleStreakUsedIDs: ["pz1"],
            highestPuzzleStreak: 25,
            highestPuzzleStorm: 40,
            dailyPuzzleStormCount: 2,
            lastPuzzleStormDate: Date()
        )
        
        let afterPuzzle = UserProgressUpdater.markPuzzleCompleted("p2", progress: initial)
        XCTAssertEqual(afterPuzzle.actualRating, 2000, "Expected actualRating to be preserved")
        XCTAssertEqual(afterPuzzle.highestPuzzleStreak, 25, "Expected highestPuzzleStreak to be preserved")
        XCTAssertEqual(afterPuzzle.currentStreak, 7, "Expected currentStreak to be preserved")
        
        let afterExam = UserProgressUpdater.markExamPassed(categoryID: "e2", nextSectionFloor: 1500, progress: initial)
        XCTAssertEqual(afterExam.actualRating, 2000, "Expected actualRating to be preserved")
        XCTAssertEqual(afterExam.highestPuzzleStorm, 40, "Expected highestPuzzleStorm to be preserved")
        
        let afterExamFail = UserProgressUpdater.registerExamFailure(categoryID: "e3", progress: initial)
        XCTAssertEqual(afterExamFail.actualRating, 2000, "Expected actualRating to be preserved")
        
        let afterOnboarding = UserProgressUpdater.completeOnboarding(progress: initial, newRating: 1400)
        XCTAssertEqual(afterOnboarding.actualRating, 2000, "Expected actualRating to be preserved")
    }
    
    func test_resetAll_returnsDefaultProgress() {
        let initial = UserProgress(
            hiddenRating: 2000,
            actualRating: 2000,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()]
        )
        
        let reset = UserProgressUpdater.resetAll(progress: initial)
        
        XCTAssertEqual(reset.hiddenRating, 500)
        XCTAssertNil(reset.actualRating)
        XCTAssertFalse(reset.onboardingComplete)
        XCTAssertTrue(reset.completedPuzzleIDs.isEmpty)
        XCTAssertTrue(reset.passedExamIDs.isEmpty)
        XCTAssertTrue(reset.examFailureTimes.isEmpty)
    }
}
