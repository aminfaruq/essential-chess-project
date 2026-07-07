//
//  OnboardingViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class OnboardingViewModel: ObservableObject, Identifiable {
    
    public let id = UUID()
    
    // MARK: - Published State
    
    @Published public private(set) var currentPuzzleIndex: Int = 0
    @Published public private(set) var currentRating: Double
    @Published public private(set) var isComplete: Bool = false
    @Published public private(set) var currentPuzzle: Puzzle?
    
    // MARK: - Dependencies & Callbacks
    
    private let pool: [Puzzle]
    public let totalPuzzles: Int
    private var usedPuzzleIDs: Set<String> = []
    
    private let calculateRating: (Double, Double, Bool) -> Double
    private let onComplete: (Double) -> Void
    
    public init(
        pool: [Puzzle],
        totalPuzzles: Int = 15,
        initialRating: Double,
        calculateRating: @escaping (Double, Double, Bool) -> Double,
        onComplete: @escaping (Double) -> Void
    ) {
        self.pool = pool
        self.totalPuzzles = totalPuzzles
        self.currentRating = initialRating
        self.calculateRating = calculateRating
        self.onComplete = onComplete
        
        fetchNextPuzzle()
    }
    
    // MARK: - Computed Properties
    
    public var progress: Double {
        guard totalPuzzles > 0 else { return 0.0 }
        return Double(currentPuzzleIndex) / Double(totalPuzzles)
    }
    
    // MARK: - Actions
    
    public func handleResult(isCorrect: Bool) {
        guard let puzzle = currentPuzzle, !isComplete else { return }
        
        // Calculate new rating using the injected pure function
        currentRating = calculateRating(currentRating, Double(puzzle.rating), isCorrect)
        
        // Advance to the next puzzle slot
        currentPuzzleIndex += 1
        
        // Check for completion
        if currentPuzzleIndex >= totalPuzzles {
            isComplete = true
        } else {
            fetchNextPuzzle()
        }
    }
    
    public func commitResults() {
        guard isComplete else { return }
        onComplete(currentRating)
    }
    
    // MARK: - Internal Logic
    
    private func fetchNextPuzzle() {
        let tolerance = 150.0
        let targetRating = currentRating
        
        let validPuzzles = pool.filter { puzzle in
            !usedPuzzleIDs.contains(puzzle.id) &&
            abs(Double(puzzle.rating) - targetRating) <= tolerance
        }
        
        let selectedPuzzle: Puzzle?
        if !validPuzzles.isEmpty {
            selectedPuzzle = validPuzzles.randomElement()
        } else {
            // Fallback: get the closest puzzle available if tolerance yields no result
            selectedPuzzle = pool
                .filter { !usedPuzzleIDs.contains($0.id) }
                .min(by: { abs(Double($0.rating) - targetRating) < abs(Double($1.rating) - targetRating) })
        }
        
        if let puzzle = selectedPuzzle {
            usedPuzzleIDs.insert(puzzle.id)
            self.currentPuzzle = puzzle
        }
    }
}
