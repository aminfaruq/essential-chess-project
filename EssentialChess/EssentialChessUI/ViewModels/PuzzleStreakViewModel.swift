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
    @Published public var showPaywall: Bool = false
    @Published public var isDailyLimitReached: Bool = false
    @Published public private(set) var showCorrectMove: Bool = false
    @Published public private(set) var isNewRecord: Bool = false
    @Published public var showResultOverlay: Bool = false
    @Published public private(set) var currentHighestStreak: Int

    // MARK: - Freemium State
    private let checkIsPro: () -> Bool
    private var dailyPuzzleStreakCount: Int
    private var lastPuzzleStreakDate: Date?

    // MARK: - Dependencies
    private let pool: [Puzzle]
    private var usedPuzzleIds: Set<String>
    private let onStreakUpdated: (Int, Set<String>) -> Void
    private let onSessionFinished: (Int) -> Void
    private let updateDailyLimits: (Int, Date) -> Void
    private let onPuzzleSolved: () -> Void

    public init(
        pool: [Puzzle],
        checkIsPro: @escaping () -> Bool,
        dailyPuzzleStreakCount: Int,
        lastPuzzleStreakDate: Date?,
        activeStreak: Int,
        activeUsedIDs: Set<String>,
        highestStreak: Int,
        onStreakUpdated: @escaping (Int, Set<String>) -> Void,
        onSessionFinished: @escaping (Int) -> Void,
        updateDailyLimits: @escaping (Int, Date) -> Void,
        onPuzzleSolved: @escaping () -> Void
    ) {
        self.pool = pool
        self.checkIsPro = checkIsPro
        self.dailyPuzzleStreakCount = dailyPuzzleStreakCount
        self.lastPuzzleStreakDate = lastPuzzleStreakDate
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
        
        if checkDailyLimit() {
            showPaywall = true
            isDailyLimitReached = true
            return
        }
        
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
    
    public func resumeAfterPurchase() {
        if checkIsPro() {
            isDailyLimitReached = false
            showPaywall = false
            onNextTapped()
        }
    }
    
    public func refreshDailyLimit() {
        if checkDailyLimit() {
            if !isDailyLimitReached {
                isDailyLimitReached = true
                showPaywall = true
            }
        } else {
            if isDailyLimitReached {
                isDailyLimitReached = false
                showPaywall = false
                if currentPuzzle == nil {
                    loadNextPuzzle()
                }
            }
        }
    }
    
    private func checkDailyLimit() -> Bool {
        if !checkIsPro() {
            let calendar = Calendar.current
            let now = Date()
            if let lastDate = lastPuzzleStreakDate, calendar.isDate(lastDate, inSameDayAs: now) {
                // Same day limit check: 1 free session per day
                if dailyPuzzleStreakCount >= 1 {
                    return true
                }
            } else {
                // New day, reset limit
                dailyPuzzleStreakCount = 0
                lastPuzzleStreakDate = now
                updateDailyLimits(dailyPuzzleStreakCount, now)
            }
        }
        return false
    }
    
    private func recordSessionStart() {
        if !checkIsPro() {
            dailyPuzzleStreakCount += 1
            lastPuzzleStreakDate = Date()
            updateDailyLimits(dailyPuzzleStreakCount, lastPuzzleStreakDate!)
        }
    }
    
    private func loadNextPuzzle() {
        let isResumingSession = (currentStreak > 0) || !usedPuzzleIds.isEmpty
        
        if !isResumingSession && !hasFailed {
            // Check limits and record session start only at the beginning of a NEW streak
            if checkDailyLimit() {
                showPaywall = true
                isDailyLimitReached = true
                currentPuzzle = nil
                return
            }
            recordSessionStart()
        }

        // Calculate target rating: Baseline 500 + 50 for each successful puzzle
        let targetRating = 500 + (currentStreak * 50)
        let range = (targetRating - 100)...(targetRating + 100)
        
        let candidates = pool.filter { 
            !usedPuzzleIds.contains($0.id) && range.contains($0.rating)
        }
        
        if let next = candidates.randomElement() {
            currentPuzzle = next
            usedPuzzleIds.insert(next.id)
            onStreakUpdated(currentStreak, usedPuzzleIds)
        } else {
            // Fallback: If no puzzles within range, find closest unused puzzle
            if let closest = pool.filter({ !usedPuzzleIds.contains($0.id) })
                                 .min(by: { abs($0.rating - targetRating) < abs($1.rating - targetRating) }) {
                currentPuzzle = closest
                usedPuzzleIds.insert(closest.id)
                onStreakUpdated(currentStreak, usedPuzzleIds)
            } else {
                // Exhausted all puzzles, recycle pool
                usedPuzzleIds.removeAll()
                if let refresh = pool.randomElement() {
                    currentPuzzle = refresh
                    usedPuzzleIds.insert(refresh.id)
                    onStreakUpdated(currentStreak, usedPuzzleIds)
                }
            }
        }
    }
}
