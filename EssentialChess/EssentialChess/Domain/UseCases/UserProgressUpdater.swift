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
        var copy = progress
        copy.hiddenRating = newRating
        copy.onboardingComplete = true
        return copy
    }
    
    public static func markPuzzleCompleted(_ puzzleID: String, progress: UserProgress) -> UserProgress {
        var copy = progress
        copy.completedPuzzleIDs.insert(puzzleID)
        return copy
    }
    
    public static func markExamPassed(categoryID: String, nextSectionFloor: Double, progress: UserProgress) -> UserProgress {
        var copy = progress
        copy.passedExamIDs.insert(categoryID)
        copy.examFailureTimes.removeValue(forKey: categoryID) // Clear failure cooldown for passed exam
        copy.hiddenRating = nextSectionFloor
        return copy
    }
    
    public static func registerExamFailure(categoryID: String, progress: UserProgress, currentDate: Date = Date()) -> UserProgress {
        var copy = progress
        copy.examFailureTimes[categoryID] = currentDate
        return copy
    }
    
    public static func resetAll(progress: UserProgress) -> UserProgress {
        // Return a default, empty state
        return UserProgress()
    }
}
