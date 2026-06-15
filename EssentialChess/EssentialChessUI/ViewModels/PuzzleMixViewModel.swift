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
    
    // MARK: - Dependencies
    private let pool: [Puzzle]
    private let calculateRating: (Double, Double, Bool) -> Double
    private let saveActualRating: (Double) -> Void
    private let onPuzzleSolved: () -> Void
    
    // MARK: - Internal State
    private var solvedPuzzleIds: Set<String> = []
    
    public init(
        pool: [Puzzle],
        hiddenRating: Double,
        actualRating: Double?,
        calculateRating: @escaping (Double, Double, Bool) -> Double,
        saveActualRating: @escaping (Double) -> Void,
        onPuzzleSolved: @escaping () -> Void
    ) {
        self.pool = pool
        self.calculateRating = calculateRating
        self.saveActualRating = saveActualRating
        self.onPuzzleSolved = onPuzzleSolved

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
            onPuzzleSolved()
        } else {
            isPuzzleFinished = true
            showCorrectMove = true
        }
    }
    
    public func handleHint() {
        guard let puzzle = currentPuzzle, !isPuzzleFinished, !hasUsedHint else { return }
        
        hasUsedHint = true
        isPuzzleFinished = true
        
        let oldRating = self.actualRating
        let puzzleRating = Double(puzzle.rating)
        let newRating = calculateRating(actualRating, puzzleRating, false)
        self.actualRating = newRating
        self.ratingChange = newRating - oldRating
        saveActualRating(newRating)
    }
    
    public func onNextTapped() {
        showCorrectMove = false
        isPuzzleFinished = false
        hasUsedHint = false
        ratingChange = nil
        loadNextPuzzle()
    }
    
    private func loadNextPuzzle() {
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
}
