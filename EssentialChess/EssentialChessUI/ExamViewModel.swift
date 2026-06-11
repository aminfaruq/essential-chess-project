//
//  ExamViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class ExamViewModel: ObservableObject {
    
    public enum ExamPhase {
        case active
        case passed
        case failed
    }
    
    // MARK: - Published State
    
    @Published public private(set) var remainingLives: Int = 3
    @Published public private(set) var solvedCount: Int = 0
    @Published public private(set) var currentIndex: Int = 0
    @Published public private(set) var phase: ExamPhase = .active
    
    public let puzzles: [Puzzle]
    
    // MARK: - Callbacks
    
    private let onPassed: () -> Void
    private let onFailed: () -> Void
    
    public init(
        puzzles: [Puzzle],
        onPassed: @escaping () -> Void,
        onFailed: @escaping () -> Void
    ) {
        self.puzzles = puzzles
        self.onPassed = onPassed
        self.onFailed = onFailed
    }
    
    // MARK: - Computed Properties
    
    public var currentPuzzle: Puzzle? {
        guard currentIndex < puzzles.count else { return nil }
        return puzzles[currentIndex]
    }
    
    public var totalPuzzles: Int {
        return puzzles.count
    }
    
    // MARK: - Actions
    
    public func handleCorrect() {
        guard phase == .active else { return }
        
        solvedCount += 1
        currentIndex += 1
        
        if currentIndex >= puzzles.count {
            phase = .passed
            onPassed()
        }
    }
    
    public func handleIncorrect() {
        guard phase == .active else { return }
        loseLife()
    }
    
    public func handleHint() {
        guard phase == .active else { return }
        loseLife()
    }
    
    // MARK: - Helpers
    
    private func loseLife() {
        remainingLives -= 1
        
        if remainingLives <= 0 {
            phase = .failed
            onFailed()
        }
    }
}
