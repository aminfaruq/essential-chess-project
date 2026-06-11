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
    
    public let puzzles: [Puzzle]
    
    // MARK: - Dependencies & Callbacks
    
    private let calculateRating: (Double, Double, Bool) -> Double
    private let onComplete: (Double) -> Void
    
    public init(
        puzzles: [Puzzle],
        initialRating: Double,
        calculateRating: @escaping (Double, Double, Bool) -> Double,
        onComplete: @escaping (Double) -> Void
    ) {
        self.puzzles = puzzles
        self.currentRating = initialRating
        self.calculateRating = calculateRating
        self.onComplete = onComplete
    }
    
    // MARK: - Computed Properties
    
    public var currentPuzzle: Puzzle? {
        guard currentPuzzleIndex < puzzles.count else { return nil }
        return puzzles[currentPuzzleIndex]
    }
    
    public var progress: Double {
        guard !puzzles.isEmpty else { return 0.0 }
        return Double(currentPuzzleIndex) / Double(puzzles.count)
    }
    
    // MARK: - Actions
    
    public func handleResult(isCorrect: Bool) {
        guard let puzzle = currentPuzzle, !isComplete else { return }
        
        // Calculate new rating using the injected pure function
        currentRating = calculateRating(currentRating, Double(puzzle.rating), isCorrect)
        
        // Advance to the next puzzle
        currentPuzzleIndex += 1
        
        // Check for completion
        if currentPuzzleIndex >= puzzles.count {
            isComplete = true
            onComplete(currentRating)
        }
    }
}
