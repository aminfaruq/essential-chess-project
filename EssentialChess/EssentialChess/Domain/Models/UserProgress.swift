//
//  UserProgress.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public enum ProFeature: String, Hashable, CaseIterable {
    case openingStudy
}

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
    public var unlockedFeatures: Set<ProFeature>
    public var dailyPuzzleMixCount: Int
    public var lastPuzzleMixDate: Date?
    public var dailyPuzzleStreakCount: Int
    public var lastPuzzleStreakDate: Date?
    public var activePuzzleStreak: Int
    public var activePuzzleStreakUsedIDs: Set<String>
    
    // NEW: Puzzle Mode Records
    public var highestPuzzleStreak: Int
    public var highestPuzzleStorm: Int
    public var dailyPuzzleStormCount: Int
    public var lastPuzzleStormDate: Date?
    
    public init(
        hiddenRating: Double = 500.0,
        actualRating: Double? = nil,
        onboardingComplete: Bool = false,
        completedPuzzleIDs: Set<String> = [],
        passedExamIDs: Set<String> = [],
        examFailureTimes: [String: Date] = [:],
        currentStreak: Int = 0,
        lastActivityDate: Date? = nil,
        unlockedFeatures: Set<ProFeature> = [],
        dailyPuzzleMixCount: Int = 0,
        lastPuzzleMixDate: Date? = nil,
        dailyPuzzleStreakCount: Int = 0,
        lastPuzzleStreakDate: Date? = nil,
        activePuzzleStreak: Int = 0,
        activePuzzleStreakUsedIDs: Set<String> = [],
        highestPuzzleStreak: Int = 0,
        highestPuzzleStorm: Int = 0,
        dailyPuzzleStormCount: Int = 0,
        lastPuzzleStormDate: Date? = nil
    ) {
        self.hiddenRating = hiddenRating
        self.actualRating = actualRating
        self.onboardingComplete = onboardingComplete
        self.completedPuzzleIDs = completedPuzzleIDs
        self.passedExamIDs = passedExamIDs
        self.examFailureTimes = examFailureTimes
        self.currentStreak = currentStreak
        self.lastActivityDate = lastActivityDate
        self.unlockedFeatures = unlockedFeatures
        self.dailyPuzzleMixCount = dailyPuzzleMixCount
        self.lastPuzzleMixDate = lastPuzzleMixDate
        self.dailyPuzzleStreakCount = dailyPuzzleStreakCount
        self.lastPuzzleStreakDate = lastPuzzleStreakDate
        self.activePuzzleStreak = activePuzzleStreak
        self.activePuzzleStreakUsedIDs = activePuzzleStreakUsedIDs
        self.highestPuzzleStreak = highestPuzzleStreak
        self.highestPuzzleStorm = highestPuzzleStorm
        self.dailyPuzzleStormCount = dailyPuzzleStormCount
        self.lastPuzzleStormDate = lastPuzzleStormDate
    }
}
