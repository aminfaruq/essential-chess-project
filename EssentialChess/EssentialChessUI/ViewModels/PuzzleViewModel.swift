//
//  PuzzleViewModel.swift
//  EssentialChess
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class PuzzleViewModel: ObservableObject {
    
    // MARK: - Published State
    
    @Published public private(set) var isSolved: Bool = false
    @Published public private(set) var wrongAttempts: Int = 0
    
    // MARK: - Properties & Callbacks
    
    private let userColorName: String
    private let onShowHint: () -> Void
    
    public init(
        userColorName: String,
        onShowHint: @escaping () -> Void
    ) {
        self.userColorName = userColorName
        self.onShowHint = onShowHint
    }
    
    // MARK: - Actions
    
    public func load(_ puzzle: Puzzle) {
        isSolved = false
        wrongAttempts = 0
    }
    
    public func markSolved() {
        isSolved = true
    }
    
    public func markWrong() {
        guard !isSolved else { return }
        wrongAttempts += 1
    }
    
    public func showHint() {
        onShowHint()
    }
    
    public func showMoveInfo() -> String {
        return "\(userColorName) to Move"
    }
}
