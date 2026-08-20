//
//  BeginnerProgressAdapter.swift
//  EssentialChess
//

import Foundation
import Combine

@MainActor
public final class BeginnerProgressAdapter: ObservableObject {
    private let store: BeginnerProgressStore
    private let subject: CurrentValueSubject<BeginnerProgress, Never>
    
    public init(store: BeginnerProgressStore) {
        self.store = store
        self.subject = CurrentValueSubject(store.currentProgress)
    }
    
    // MARK: - Inputs
    
    public func markCompleted(puzzleID: String) {
        store.markCompleted(puzzleID: puzzleID)
        subject.send(store.currentProgress)
    }
    
    public func clearProgress() {
        store.clearProgress()
        subject.send(store.currentProgress)
    }
    
    // MARK: - Outputs
    
    public func publisher() -> AnyPublisher<BeginnerProgress, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public var currentProgress: BeginnerProgress {
        subject.value
    }
}
