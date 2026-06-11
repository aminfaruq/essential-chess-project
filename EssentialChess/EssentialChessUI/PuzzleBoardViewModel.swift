//
//  Untitled.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class PuzzleBoardViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public var currentActiveIndex: Int = 0
    @Published public var isSolved: Bool = false
    @Published public var wrongAttempts: Int = 0
    @Published public var isSessionComplete: Bool = false
    
    public let puzzles: [Puzzle]
    private var completedPuzzleIDs: Set<String>
    
    // MARK: - Callbacks
    
    private let onPuzzleSolved: (String) -> Void
    
    // MARK: - Initialization
    
    public init(
        puzzles: [Puzzle],
        initialCompletedIDs: Set<String>,
        onPuzzleSolved: @escaping (String) -> Void
    ) {
        self.puzzles = puzzles
        self.completedPuzzleIDs = initialCompletedIDs
        self.onPuzzleSolved = onPuzzleSolved
        
        // Set initial index based on progression
        let themeFullyCompleted = !puzzles.isEmpty && puzzles.allSatisfy { initialCompletedIDs.contains($0.id) }
        let frontierIndex = puzzles.firstIndex { !initialCompletedIDs.contains($0.id) } ?? 0
        
        self.currentActiveIndex = themeFullyCompleted ? 0 : frontierIndex
        self.reset()
    }
    
    // MARK: - Computed Properties
    
    public var currentPuzzle: Puzzle? {
        guard currentActiveIndex < puzzles.count else { return nil }
        return puzzles[currentActiveIndex]
    }
    
    public var highestUnsolvedIndex: Int {
        puzzles.firstIndex { !isCompleted($0) } ?? 0
    }
    
    public var isThemeFullyCompleted: Bool {
        !puzzles.isEmpty && puzzles.allSatisfy { isCompleted($0) }
    }
    
    public var unlockedCount: Int {
        isThemeFullyCompleted ? puzzles.count : min(highestUnsolvedIndex + 1, puzzles.count)
    }
    
    public func isCompleted(_ puzzle: Puzzle) -> Bool {
        completedPuzzleIDs.contains(puzzle.id)
    }
    
    // MARK: - Actions
    
    public func markSolved() {
        guard let puzzle = currentPuzzle, !isSolved else { return }
        
        isSolved = true
        completedPuzzleIDs.insert(puzzle.id)
        onPuzzleSolved(puzzle.id)
    }
    
    public func markWrong() {
        guard !isSolved else { return }
        wrongAttempts += 1
    }
    
    public func triggerNext() {
        if isThemeFullyCompleted {
            // Linear progression through a completed theme
            if currentActiveIndex < puzzles.count - 1 {
                currentActiveIndex += 1
                reset()
            } else {
                isSessionComplete = true
            }
        } else {
            // Always jump to the frontier
            let next = highestUnsolvedIndex
            if next >= puzzles.count {
                isSessionComplete = true
            } else {
                currentActiveIndex = next
                reset()
            }
        }
    }
    
    public func jumpTo(index: Int) {
        guard index < unlockedCount else { return }
        currentActiveIndex = index
        reset()
    }
    
    // MARK: - Helpers
    
    private func reset() {
        isSolved = false
        wrongAttempts = 0
    }
}
