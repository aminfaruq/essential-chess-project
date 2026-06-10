//
//  UserProgress.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct UserProgress: Equatable {
    public let hiddenRating: Double
    public let onboardingComplete: Bool
    public let completedPuzzleIDs: Set<String>
    public let passedExamIDs: Set<String>
    public let examFailureTimes: [String: Date]
    
    public init(
        hiddenRating: Double = 500.0,
        onboardingComplete: Bool = false,
        completedPuzzleIDs: Set<String> = [],
        passedExamIDs: Set<String> = [],
        examFailureTimes: [String: Date] = [:]
    ) {
        self.hiddenRating = hiddenRating
        self.onboardingComplete = onboardingComplete
        self.completedPuzzleIDs = completedPuzzleIDs
        self.passedExamIDs = passedExamIDs
        self.examFailureTimes = examFailureTimes
    }
}
