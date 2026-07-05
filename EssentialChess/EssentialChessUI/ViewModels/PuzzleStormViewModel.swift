//
//  PuzzleStormViewModel.swift
//  EssentialChess
//
//  Created by App on 21/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class PuzzleStormViewModel: ObservableObject, Identifiable {
    public let id = UUID()

    // MARK: - Published State
    @Published public private(set) var currentPuzzle: Puzzle?
    @Published public private(set) var currentScore: Int = 0
    @Published public private(set) var currentCombo: Int = 0
    @Published public private(set) var highestCombo: Int = 0
    @Published public private(set) var timeRemaining: Int = 180
    @Published public private(set) var isGameActive: Bool = false
    @Published public private(set) var isGameOver: Bool = false
    
    // UI Effects
    @Published public var showPenaltyIndicator: Bool = false
    @Published public var showBonusIndicator: Bool = false
    @Published public private(set) var lastBonusAmount: Int = 0
    
    // Freemium & Limits (Commented out — app is now fully free)
    // @Published public var showPaywall: Bool = false
    // @Published public var isDailyLimitReached: Bool = false
    @Published public private(set) var currentHighestScore: Int
    @Published public private(set) var isNewRecord: Bool = false

    // MARK: - Dependencies
    private let pool: [Puzzle]
    private var usedPuzzleIds: Set<String> = []
    
    // MARK: - Freemium State (Commented out — app is now fully free)
    // private let checkIsPro: () -> Bool
    // private var dailyPuzzleStormCount: Int
    // private var lastPuzzleStormDate: Date?
    
    private let onScoreUpdated: (Int) -> Void
    private let onSessionFinished: (Int) -> Void
    private let updateDailyLimits: (Int, Date) -> Void
    private let onPuzzleSolved: () -> Void
    
    private var timerCancellable: AnyCancellable?

    public init(
        pool: [Puzzle],
        // checkIsPro: @escaping () -> Bool,
        // dailyPuzzleStormCount: Int,
        // lastPuzzleStormDate: Date?,
        highestScore: Int,
        onScoreUpdated: @escaping (Int) -> Void,
        onSessionFinished: @escaping (Int) -> Void,
        updateDailyLimits: @escaping (Int, Date) -> Void,
        onPuzzleSolved: @escaping () -> Void
    ) {
        self.pool = pool.shuffled()
        // self.checkIsPro = checkIsPro
        // self.dailyPuzzleStormCount = dailyPuzzleStormCount
        // self.lastPuzzleStormDate = lastPuzzleStormDate
        self.currentHighestScore = highestScore
        
        self.onScoreUpdated = onScoreUpdated
        self.onSessionFinished = onSessionFinished
        self.updateDailyLimits = updateDailyLimits
        self.onPuzzleSolved = onPuzzleSolved
    }
    
    // MARK: - Actions
    
    public func onStartTapped() {
        // MARK: - Freemium daily limit check (commented out — app is now fully free)
        // if checkDailyLimit() {
        //     showPaywall = true
        //     isDailyLimitReached = true
        //     return
        // }
        
        // Reset state for a new session
        isGameOver = false
        isNewRecord = false
        currentScore = 0
        currentCombo = 0
        highestCombo = 0
        timeRemaining = 180
        usedPuzzleIds.removeAll()
        
        // recordSessionStart()
        isGameActive = true
        loadNextPuzzle()
        startTimer()
    }
    
    public func handlePuzzleCompletion(isCorrect: Bool) {
        guard isGameActive, !isGameOver else { return }
        
        if isCorrect {
            currentScore += 1
            currentCombo += 1
            if currentCombo > highestCombo {
                highestCombo = currentCombo
            }
            
            checkForComboBonus()
            loadNextPuzzle()
            onPuzzleSolved()
        } else {
            // Mistake
            currentCombo = 0
            timeRemaining -= 10
            showPenaltyIndicator = true
            
            if timeRemaining <= 0 {
                timeRemaining = 0
                endGame()
            } else {
                loadNextPuzzle()
            }
        }
    }
    
    // MARK: - Freemium resume/refresh/limit (commented out — app is now fully free)
    // public func resumeAfterPurchase() {
    //     if checkIsPro() {
    //         isDailyLimitReached = false
    //         showPaywall = false
    //         onStartTapped()
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
    //         }
    //     }
    // }
    
    // MARK: - Mechanics
    
    private func checkForComboBonus() {
        let bonus: Int
        switch currentCombo {
        case 5: bonus = 3
        case 12: bonus = 4
        case 20: bonus = 5
        case 30: bonus = 6
        case 40: bonus = 7
        case 50: bonus = 8
        case 60: bonus = 9
        case 70: bonus = 10
        case 80: bonus = 11
        case 90: bonus = 12
        case 100: bonus = 15
        default: bonus = 0
        }
        
        if bonus > 0 {
            timeRemaining += bonus
            lastBonusAmount = bonus
            showBonusIndicator = true
            // reset after a short time could be handled by UI via task(id:) or onReceive
        }
    }
    
    private func startTimer() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isGameActive, !self.isGameOver else { return }
                
                self.timeRemaining -= 1
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.endGame()
                }
            }
    }
    
    private func endGame() {
        isGameActive = false
        isGameOver = true
        timerCancellable?.cancel()
        currentPuzzle = nil
        
        if currentScore > currentHighestScore {
            isNewRecord = true
            currentHighestScore = currentScore
            onScoreUpdated(currentHighestScore)
        }
        
        onSessionFinished(currentScore)
    }
    
    // MARK: - Freemium Limits (commented out — app is now fully free)
    //
    // private func checkDailyLimit() -> Bool {
    //     if !checkIsPro() {
    //         let calendar = Calendar.current
    //         let now = Date()
    //         if let lastDate = lastPuzzleStormDate, calendar.isDate(lastDate, inSameDayAs: now) {
    //             if dailyPuzzleStormCount >= 1 {
    //                 return true
    //             }
    //         } else {
    //             dailyPuzzleStormCount = 0
    //             lastPuzzleStormDate = now
    //             updateDailyLimits(dailyPuzzleStormCount, now)
    //         }
    //     }
    //     return false
    // }
    //
    // private func recordSessionStart() {
    //     if !checkIsPro() {
    //         dailyPuzzleStormCount += 1
    //         lastPuzzleStormDate = Date()
    //         updateDailyLimits(dailyPuzzleStormCount, lastPuzzleStormDate!)
    //     }
    // }
    
    // MARK: - Puzzle Loading
    
    private func loadNextPuzzle() {
        // Starts very easy (~300) and gets progressively harder
        let targetRating = 300 + (currentScore * 30) // Slow ramp up compared to Streak
        let range = (targetRating - 200)...(targetRating + 200)
        
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
        } else {
            // Ultimate fallback (should only hit if pool is completely exhausted)
            usedPuzzleIds.removeAll()
            if let refresh = pool.randomElement() {
                currentPuzzle = refresh
                usedPuzzleIds.insert(refresh.id)
            }
        }
    }
}
