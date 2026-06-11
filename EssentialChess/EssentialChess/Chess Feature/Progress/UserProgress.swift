//
//  UserProgress.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct UserProgress: Equatable {
    public let hiddenRating: Double
    public var onboardingComplete: Bool
    public var completedPuzzleIDs: Set<String>
    public var passedExamIDs: Set<String>
    public var examFailureTimes: [String: Date]
    
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
