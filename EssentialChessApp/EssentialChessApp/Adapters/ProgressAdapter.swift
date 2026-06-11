//
//  ProgressAdapter.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import EssentialChess

public final class ProgressAdapter {
    private let store: ProgressStore
    private let subject: CurrentValueSubject<UserProgress, Never>
    
    public init(store: ProgressStore) {
        self.store = store
        // Initialize with default progress to prevent crashes
        self.subject = CurrentValueSubject<UserProgress, Never>(
            UserProgress(
                hiddenRating: 500.0,
                onboardingComplete: false,
                completedPuzzleIDs: [],
                passedExamIDs: [],
                examFailureTimes: [:]
            )
        )
    }
    
    // MARK: - Inputs
    
    public func load(completion: @escaping () -> Void) {
        store.retrieve { [weak self] result in
            if let progress = (try? result.get()) ?? nil {
                self?.subject.send(progress)
            }
            completion()
        }
    }
    
    public func update(_ modifier: (inout UserProgress) -> Void) {
        var current = subject.value
        modifier(&current)
        subject.send(current)
        
        // Save to UserDefaults in the background
        store.insert(current) { _ in }
    }
    
    // MARK: - Outputs
    
    public func publisher() -> AnyPublisher<UserProgress, Never> {
        return subject.eraseToAnyPublisher()
    }
    
    // Helper to read current state synchronously if needed by Composer
    public var currentProgress: UserProgress {
        return subject.value
    }
}
