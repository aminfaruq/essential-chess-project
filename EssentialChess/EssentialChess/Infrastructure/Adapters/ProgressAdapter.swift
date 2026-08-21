//
//  ProgressAdapter.swift
//  EssentialChessApp
//
//  Created by Amin faruq on 11/06/26.
//

import Foundation
import Combine
import OSLog

@MainActor
public final class ProgressAdapter {
    private let store: ProgressLoader
    private let subject: CurrentValueSubject<UserProgress, Never>
    
    public init(store: ProgressLoader) {
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
            Task { @MainActor in
                switch result {
                case .success(let progress):
                    if let progress = progress {
                        self?.subject.send(progress)
                    }
                case .failure(let error):
                    os_log(.error, "ProgressAdapter: Failed to load progress: %{public}@", error.localizedDescription)
                }
                completion()
            }
        }
    }
    
    public func update(_ modifier: (inout UserProgress) -> Void) {
        var current = subject.value
        modifier(&current)
        
        // Publish on the main thread to satisfy Combine/SwiftUI requirements
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
