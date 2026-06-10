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
    
    func test_resetAll_returnsDefaultProgress() {
        let initial = UserProgress(
            hiddenRating: 2000,
            onboardingComplete: true,
            completedPuzzleIDs: ["p1"],
            passedExamIDs: ["e1"],
            examFailureTimes: ["e2": Date()]
        )
        
        let reset = UserProgressUpdater.resetAll(progress: initial)
        
        XCTAssertEqual(reset.hiddenRating, 500)
        XCTAssertFalse(reset.onboardingComplete)
        XCTAssertTrue(reset.completedPuzzleIDs.isEmpty)
        XCTAssertTrue(reset.passedExamIDs.isEmpty)
        XCTAssertTrue(reset.examFailureTimes.isEmpty)
    }
}
