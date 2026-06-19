//
//  UserProgress.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct UserProgress: Equatable {
    public var hiddenRating: Double
    public var actualRating: Double?
    public var onboardingComplete: Bool
    public var completedPuzzleIDs: Set<String>
    public var passedExamIDs: Set<String>
    public var examFailureTimes: [String: Date]
    
    // NEW: Daily Streak Properties
    public var currentStreak: Int
    public var lastActivityDate: Date?
    
    // NEW: Freemium & Limits
    public var isPro: Bool
    public var dailyPuzzleMixCount: Int
    public var lastPuzzleMixDate: Date?
    
    // NEW: Puzzle Mode Records
    public var highestPuzzleStreak: Int
    public var highestPuzzleStorm: Int
    
    public init(
        hiddenRating: Double = 500.0,
        actualRating: Double? = nil,
        onboardingComplete: Bool = false,
        completedPuzzleIDs: Set<String> = [],
        passedExamIDs: Set<String> = [],
        examFailureTimes: [String: Date] = [:],
        currentStreak: Int = 0,
        lastActivityDate: Date? = nil,
        isPro: Bool = false,
        dailyPuzzleMixCount: Int = 0,
        lastPuzzleMixDate: Date? = nil,
        highestPuzzleStreak: Int = 0,
        highestPuzzleStorm: Int = 0
    ) {
        self.hiddenRating = hiddenRating
        self.actualRating = actualRating
        self.onboardingComplete = onboardingComplete
        self.completedPuzzleIDs = completedPuzzleIDs
        self.passedExamIDs = passedExamIDs
        self.examFailureTimes = examFailureTimes
        self.currentStreak = currentStreak
        self.lastActivityDate = lastActivityDate
        self.isPro = isPro
        self.dailyPuzzleMixCount = dailyPuzzleMixCount
        self.lastPuzzleMixDate = lastPuzzleMixDate
        self.highestPuzzleStreak = highestPuzzleStreak
        self.highestPuzzleStorm = highestPuzzleStorm
    }
}
