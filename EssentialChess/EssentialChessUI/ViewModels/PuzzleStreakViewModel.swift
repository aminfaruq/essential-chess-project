//
//  PuzzleStreakViewModel.swift
//  EssentialChess
//
//  Created by App on 15/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class PuzzleStreakViewModel: ObservableObject, Identifiable {
    public let id = UUID()

    // MARK: - Published State
    @Published public private(set) var currentPuzzle: Puzzle?
    @Published public private(set) var currentStreak: Int = 0
    @Published public private(set) var isPuzzleFinished: Bool = false
    @Published public private(set) var hasFailed: Bool = false
    // MARK: - Freemium State (Commented out — app is now fully free)
    // @Published public var showPaywall: Bool = false
    // @Published public var isDailyLimitReached: Bool = false
    //
    // private let checkIsPro: () -> Bool
    // private var dailyPuzzleStreakCount: Int
    // private var lastPuzzleStreakDate: Date?
    @Published public private(set) var showCorrectMove: Bool = false
    @Published public private(set) var isNewRecord: Bool = false
    @Published public var showResultOverlay: Bool = false
    @Published public private(set) var currentHighestStreak: Int

    // MARK: - Dependencies
    private let pool: [Puzzle]
    private var usedPuzzleIds: Set<String>
    private let onStreakUpdated: (Int, Set<String>) -> Void
    private let onSessionFinished: (Int) -> Void
    private let updateDailyLimits: (Int, Date) -> Void
    private let onPuzzleSolved: () -> Void

    public init(
        pool: [Puzzle],
        // checkIsPro: @escaping () -> Bool,
        // dailyPuzzleStreakCount: Int,
        // lastPuzzleStreakDate: Date?,
        activeStreak: Int,
        activeUsedIDs: Set<String>,
        highestStreak: Int,
        onStreakUpdated: @escaping (Int, Set<String>) -> Void,
        onSessionFinished: @escaping (Int) -> Void,
        updateDailyLimits: @escaping (Int, Date) -> Void,
        onPuzzleSolved: @escaping () -> Void
    ) {
        self.pool = pool.shuffled()
        // self.checkIsPro = checkIsPro
        // self.dailyPuzzleStreakCount = dailyPuzzleStreakCount
        // self.lastPuzzleStreakDate = lastPuzzleStreakDate
        self.currentStreak = activeStreak
        self.usedPuzzleIds = activeUsedIDs
        self.currentHighestStreak = highestStreak
        self.onStreakUpdated = onStreakUpdated
        self.onSessionFinished = onSessionFinished
        self.updateDailyLimits = updateDailyLimits
        self.onPuzzleSolved = onPuzzleSolved

        loadNextPuzzle()
    }
    
    // MARK: - Actions
    
    public func handlePuzzleCompletion(isCorrect: Bool) {
        guard !isPuzzleFinished else { return }
        
        if isCorrect {
            currentStreak += 1
            loadNextPuzzle()
            onPuzzleSolved()
        } else {
            hasFailed = true
            isPuzzleFinished = true
            showCorrectMove = true
            isNewRecord = currentStreak > currentHighestStreak
            onStreakUpdated(0, []) // Clear active session on failure
            onSessionFinished(currentStreak)
            
            // Show result overlay after a short delay so user can see the correct move
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else { return }
                self.showResultOverlay = true
            }
        }
    }
    
    public func onNextTapped() {
        showResultOverlay = false
        
        // MARK: - Freemium daily limit check (commented out — app is now fully free)
        // if checkDailyLimit() {
        //     showPaywall = true
        //     isDailyLimitReached = true
        //     return
        // }
        
        // Reset state for a new session
        hasFailed = false
        isPuzzleFinished = false
        showCorrectMove = false
        
        if isNewRecord {
            currentHighestStreak = currentStreak
        }
        isNewRecord = false
        currentStreak = 0
        usedPuzzleIds.removeAll()
        onStreakUpdated(0, [])
        
        loadNextPuzzle()
    }
    
    // MARK: - Freemium resume after purchase (commented out — app is now fully free)
    // public func resumeAfterPurchase() {
    //     if checkIsPro() {
    //         isDailyLimitReached = false
    //         showPaywall = false
    //         onNextTapped()
    //     }
    // }
    //
    // public func refreshDailyLimit() {
    //     if checkDailyLimit() {
    //         if !isDailyLimitReached {
    //             isDailyLimitReached = true
    //             showPaywall = true
    //         }
    //     } else {
    //         if isDailyLimitReached {
    //             isDailyLimitReached = false
    //             showPaywall = false
    //             if currentPuzzle == nil {
    //                 loadNextPuzzle()
    //             }
    //         }
    //     }
    // }
    //
    // private func checkDailyLimit() -> Bool {
    //     if !checkIsPro() {
    //         let calendar = Calendar.current
    //         let now = Date()
    //         if let lastDate = lastPuzzleStreakDate, calendar.isDate(lastDate, inSameDayAs: now) {
    //             if dailyPuzzleStreakCount >= 1 {
    //                 return true
    //             }
    //         } else {
    //             dailyPuzzleStreakCount = 0
    //             lastPuzzleStreakDate = now
    //             updateDailyLimits(dailyPuzzleStreakCount, now)
    //         }
    //     }
    //     return false
    // }
    //
    // private func recordSessionStart() {
    //     if !checkIsPro() {
    //         dailyPuzzleStreakCount += 1
    //         lastPuzzleStreakDate = Date()
    //         updateDailyLimits(dailyPuzzleStreakCount, lastPuzzleStreakDate!)
    //     }
    // }
    
    private func loadNextPuzzle() {
        let isResumingSession = (currentStreak > 0) || !usedPuzzleIds.isEmpty
        
        // MARK: - Freemium daily limit check (commented out — app is now fully free)
        // if !isResumingSession && !hasFailed {
        //     if checkDailyLimit() {
        //         showPaywall = true
        //         isDailyLimitReached = true
        //         currentPuzzle = nil
        //         return
        //     }
        //     recordSessionStart()
        // }

        // Calculate target rating: Baseline 500 + 50 for each successful puzzle
        let targetRating = 500 + (currentStreak * 50)
        let range = (targetRating - 100)...(targetRating + 100)
        
        var candidates = pool.filter { 
            !usedPuzzleIds.contains($0.id) && range.contains($0.rating)
        }
        
        // If the database has very few puzzles in this specific rating range,
        // it will cause the same few puzzles to repeat. To fix this, we ensure
        // there are always at least 50 candidates to choose from by picking the closest ones.
        if candidates.count < 50 {
            let unused = pool.filter { !usedPuzzleIds.contains($0.id) }
            let sortedByClosest = unused.sorted { abs($0.rating - targetRating) < abs($1.rating - targetRating) }
            candidates = Array(sortedByClosest.prefix(50))
        }
        
        if let next = candidates.randomElement() {
            currentPuzzle = next
            usedPuzzleIds.insert(next.id)
            onStreakUpdated(currentStreak, usedPuzzleIds)
        } else {
            // Ultimate fallback (should only hit if pool is completely exhausted)
            usedPuzzleIds.removeAll()
            if let refresh = pool.randomElement() {
                currentPuzzle = refresh
                usedPuzzleIds.insert(refresh.id)
                onStreakUpdated(currentStreak, usedPuzzleIds)
            }
        }
    }
}
