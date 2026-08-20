//
//  ProgressCacheDTO.swift
//  EssentialChess
//
//  Created by Amin faruq on 07/07/26.
//
import Foundation
// MARK: - DTO (Data Transfer Object)

public struct ProgressCacheDTO: Codable {
    private let hiddenRating: Double
    private let actualRating: Double?
    private let onboardingComplete: Bool
    private let completedPuzzleIDs: Set<String>
    private let passedExamIDs: Set<String>
    private let examFailureTimes: [String: Date]
    private let currentStreak: Int
    private let lastActivityDate: Date?
    private let isPro: Bool?
    private let unlockedFeatures: Set<String>?
    private let dailyPuzzleMixCount: Int?
    private let lastPuzzleMixDate: Date?
    private let dailyPuzzleStreakCount: Int?
    private let lastPuzzleStreakDate: Date?
    private let activePuzzleStreak: Int?
    private let activePuzzleStreakUsedIDs: Set<String>?
    private let highestPuzzleStreak: Int?
    private let highestPuzzleStorm: Int?
    private let dailyPuzzleStormCount: Int?
    private let lastPuzzleStormDate: Date?
    
    public init(from model: UserProgress) {
        self.hiddenRating = model.hiddenRating
        self.actualRating = model.actualRating
        self.onboardingComplete = model.onboardingComplete
        self.completedPuzzleIDs = model.completedPuzzleIDs
        self.passedExamIDs = model.passedExamIDs
        self.examFailureTimes = model.examFailureTimes
        self.currentStreak = model.currentStreak
        self.lastActivityDate = model.lastActivityDate
        self.isPro = nil
        self.unlockedFeatures = Set(model.unlockedFeatures.map(\.rawValue))
        self.dailyPuzzleMixCount = model.dailyPuzzleMixCount
        self.lastPuzzleMixDate = model.lastPuzzleMixDate
        self.dailyPuzzleStreakCount = model.dailyPuzzleStreakCount
        self.lastPuzzleStreakDate = model.lastPuzzleStreakDate
        self.activePuzzleStreak = model.activePuzzleStreak
        self.activePuzzleStreakUsedIDs = model.activePuzzleStreakUsedIDs
        self.highestPuzzleStreak = model.highestPuzzleStreak
        self.highestPuzzleStorm = model.highestPuzzleStorm
        self.dailyPuzzleStormCount = model.dailyPuzzleStormCount
        self.lastPuzzleStormDate = model.lastPuzzleStormDate
    }
    
    public func toModel() -> UserProgress {
        UserProgress(
            hiddenRating: hiddenRating,
            actualRating: actualRating,
            onboardingComplete: onboardingComplete,
            completedPuzzleIDs: completedPuzzleIDs,
            passedExamIDs: passedExamIDs,
            examFailureTimes: examFailureTimes,
            currentStreak: currentStreak,
            lastActivityDate: lastActivityDate,
            unlockedFeatures: unlockedFeatures.map { Set($0.compactMap(ProFeature.init(rawValue:))) } ?? [],
            dailyPuzzleMixCount: dailyPuzzleMixCount ?? 0,
            lastPuzzleMixDate: lastPuzzleMixDate,
            dailyPuzzleStreakCount: dailyPuzzleStreakCount ?? 0,
            lastPuzzleStreakDate: lastPuzzleStreakDate,
            activePuzzleStreak: activePuzzleStreak ?? 0,
            activePuzzleStreakUsedIDs: activePuzzleStreakUsedIDs ?? [],
            highestPuzzleStreak: highestPuzzleStreak ?? 0,
            highestPuzzleStorm: highestPuzzleStorm ?? 0,
            dailyPuzzleStormCount: dailyPuzzleStormCount ?? 0,
            lastPuzzleStormDate: lastPuzzleStormDate
        )
    }
}
