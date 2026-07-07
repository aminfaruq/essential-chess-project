//
//  UserProgressUpdater.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct UserProgressUpdater {
    
    // MARK: - Mutations
    
    public static func completeOnboarding(progress: UserProgress, newRating: Double) -> UserProgress {
        return UserProgress(
            hiddenRating: newRating,
            onboardingComplete: true,
            completedPuzzleIDs: progress.completedPuzzleIDs,
            passedExamIDs: progress.passedExamIDs,
            examFailureTimes: progress.examFailureTimes
        )
    }
    
    public static func markPuzzleCompleted(_ puzzleID: String, progress: UserProgress) -> UserProgress {
        var updatedPuzzleIDs = progress.completedPuzzleIDs
        updatedPuzzleIDs.insert(puzzleID)
        
        return UserProgress(
            hiddenRating: progress.hiddenRating,
            onboardingComplete: progress.onboardingComplete,
            completedPuzzleIDs: updatedPuzzleIDs,
            passedExamIDs: progress.passedExamIDs,
            examFailureTimes: progress.examFailureTimes
        )
    }
    
    public static func markExamPassed(categoryID: String, nextSectionFloor: Double, progress: UserProgress) -> UserProgress {
        var updatedPassedExamIDs = progress.passedExamIDs
        updatedPassedExamIDs.insert(categoryID)
        
        var updatedFailureTimes = progress.examFailureTimes
        updatedFailureTimes.removeValue(forKey: categoryID) // Clear failure cooldown for passed exam
        
        return UserProgress(
            hiddenRating: nextSectionFloor,
            onboardingComplete: progress.onboardingComplete,
            completedPuzzleIDs: progress.completedPuzzleIDs,
            passedExamIDs: updatedPassedExamIDs,
            examFailureTimes: updatedFailureTimes
        )
    }
    
    public static func registerExamFailure(categoryID: String, progress: UserProgress, currentDate: Date = Date()) -> UserProgress {
        var updatedFailureTimes = progress.examFailureTimes
        updatedFailureTimes[categoryID] = currentDate
        
        return UserProgress(
            hiddenRating: progress.hiddenRating,
            onboardingComplete: progress.onboardingComplete,
            completedPuzzleIDs: progress.completedPuzzleIDs,
            passedExamIDs: progress.passedExamIDs,
            examFailureTimes: updatedFailureTimes
        )
    }
    
    public static func resetAll(progress: UserProgress) -> UserProgress {
        // Return a default, empty state
        return UserProgress()
    }
}
