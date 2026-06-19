//
//  PuzzleMixViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 15/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class PuzzleMixViewModel: ObservableObject, Identifiable {
    
    public let id = UUID()

    // MARK: - Published State
    @Published public private(set) var actualRating: Double
    @Published public private(set) var currentPuzzle: Puzzle?
    @Published public private(set) var showCorrectMove: Bool = false
    @Published public private(set) var isPuzzleFinished: Bool = false
    @Published public private(set) var hasUsedHint: Bool = false
    @Published public private(set) var ratingChange: Double? = nil
    @Published public private(set) var hasSeenHintWarning: Bool
    @Published public var showPaywall: Bool = false
    @Published public var isDailyLimitReached: Bool = false
    
    // MARK: - Freemium State
    private let checkIsPro: () -> Bool
    private var dailyPuzzleMixCount: Int
    private var lastPuzzleMixDate: Date?
    
    // MARK: - Dependencies
    private let pool: [Puzzle]
    private let calculateRating: (Double, Double, Bool) -> Double
    private let saveActualRating: (Double) -> Void
    private let saveHasSeenHintWarning: (Bool) -> Void
    private let onPuzzleSolved: () -> Void
    private let updateDailyLimits: (Int, Date) -> Void
    
    // MARK: - Internal State
    private var solvedPuzzleIds: Set<String> = []
    
    public init(
        pool: [Puzzle],
        hiddenRating: Double,
        actualRating: Double?,
        checkIsPro: @escaping () -> Bool,
        dailyPuzzleMixCount: Int,
        lastPuzzleMixDate: Date?,
        hasSeenHintWarning: Bool,
        calculateRating: @escaping (Double, Double, Bool) -> Double,
        saveActualRating: @escaping (Double) -> Void,
        saveHasSeenHintWarning: @escaping (Bool) -> Void,
        onPuzzleSolved: @escaping () -> Void,
        updateDailyLimits: @escaping (Int, Date) -> Void
    ) {
        self.pool = pool
        self.checkIsPro = checkIsPro
        self.dailyPuzzleMixCount = dailyPuzzleMixCount
        self.lastPuzzleMixDate = lastPuzzleMixDate
        self.hasSeenHintWarning = hasSeenHintWarning
        self.calculateRating = calculateRating
        self.saveActualRating = saveActualRating
        self.saveHasSeenHintWarning = saveHasSeenHintWarning
        self.onPuzzleSolved = onPuzzleSolved
        self.updateDailyLimits = updateDailyLimits

        if let current = actualRating {
            self.actualRating = current
        } else {
            self.actualRating = hiddenRating
            saveActualRating(hiddenRating)
        }
        
        loadNextPuzzle()
    }
    
    // MARK: - Actions
    
    public func handlePuzzleCompletion(isCorrect: Bool) {
        guard let puzzle = currentPuzzle, !isPuzzleFinished else { return }
        
        let oldRating = self.actualRating
        let puzzleRating = Double(puzzle.rating)
        let newRating = calculateRating(actualRating, puzzleRating, isCorrect)
        self.actualRating = newRating
        self.ratingChange = newRating - oldRating
        saveActualRating(newRating)
        
        if isCorrect {
            isPuzzleFinished = true
            showCorrectMove = false
            recordActivity()
            onPuzzleSolved()
        } else {
            isPuzzleFinished = true
            showCorrectMove = true
            recordActivity()
        }
    }
    
    public func decreaseRating() {
        guard let puzzle = currentPuzzle, !isPuzzleFinished, !hasUsedHint else { return }
        
        hasUsedHint = true
        isPuzzleFinished = true
        
        let oldRating = self.actualRating
        let puzzleRating = Double(puzzle.rating)
        let newRating = calculateRating(actualRating, puzzleRating, false)
        self.actualRating = newRating
        self.ratingChange = newRating - oldRating
        saveActualRating(newRating)
        
        recordActivity()
    }
    
    public func markHintWarningAsSeen() {
        hasSeenHintWarning = true
        saveHasSeenHintWarning(true)
    }
    
    public func onNextTapped() {
        if checkDailyLimit() {
            showPaywall = true
            isDailyLimitReached = true
            return
        }
        
        showCorrectMove = false
        isPuzzleFinished = false
        hasUsedHint = false
        ratingChange = nil
        loadNextPuzzle()
    }
    
    public func resumeAfterPurchase() {
        if checkIsPro() {
            isDailyLimitReached = false
            showCorrectMove = false
            isPuzzleFinished = false
            hasUsedHint = false
            ratingChange = nil
            loadNextPuzzle()
        }
    }
    
    private func checkDailyLimit() -> Bool {
        if !checkIsPro() {
            let calendar = Calendar.current
            let now = Date()
            if let lastDate = lastPuzzleMixDate, calendar.isDate(lastDate, inSameDayAs: now) {
                // Same day
                if dailyPuzzleMixCount >= 7 {
                    return true
                }
            } else {
                // New day, reset count
                dailyPuzzleMixCount = 0
                lastPuzzleMixDate = now
                updateDailyLimits(dailyPuzzleMixCount, now)
            }
        }
        return false
    }
    
    private func loadNextPuzzle() {
        if checkDailyLimit() {
            showPaywall = true
            isDailyLimitReached = true
            return
        }
        
        let range = (actualRating - 150)...(actualRating + 150)
        let candidates = pool.filter { 
            !solvedPuzzleIds.contains($0.id) && 
            range.contains(Double($0.rating)) 
        }
        
        if let next = candidates.randomElement() {
            currentPuzzle = next
            solvedPuzzleIds.insert(next.id)
        } else {
            // Fallback: Find closest rating puzzle
            if let closest = pool.filter({ !solvedPuzzleIds.contains($0.id) })
                                 .min(by: { abs(Double($0.rating) - actualRating) < abs(Double($1.rating) - actualRating) }) {
                currentPuzzle = closest
                solvedPuzzleIds.insert(closest.id)
            } else {
                // All solved, cycle pool
                solvedPuzzleIds.removeAll()
                if let refresh = pool.randomElement() {
                    currentPuzzle = refresh
                    solvedPuzzleIds.insert(refresh.id)
                }
            }
        }
    }
    
    private func recordActivity() {
        if !checkIsPro() {
            dailyPuzzleMixCount += 1
            lastPuzzleMixDate = Date()
            updateDailyLimits(dailyPuzzleMixCount, lastPuzzleMixDate!)
        }
    }
}
