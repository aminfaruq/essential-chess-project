import Foundation
import Combine

public struct BeginnerProgress: Equatable {
    public let completedPuzzleIDs: Set<String>
    
    public init(completedPuzzleIDs: Set<String> = []) {
        self.completedPuzzleIDs = completedPuzzleIDs
    }
}

public protocol BeginnerProgressStore {
    var progressPublisher: AnyPublisher<BeginnerProgress, Never> { get }
    var currentProgress: BeginnerProgress { get }
    
    func markCompleted(puzzleID: String)
    func clearProgress()
}

public final class UserDefaultsBeginnerProgressStore: BeginnerProgressStore {
    private let userDefaults: UserDefaults
    private let key: String
    
    private let subject: CurrentValueSubject<BeginnerProgress, Never>
    
    public init(userDefaults: UserDefaults = .standard, key: String = "beginner_completed_puzzles") {
        self.userDefaults = userDefaults
        self.key = key
        
        let loadedIDs = userDefaults.stringArray(forKey: key) ?? []
        let initialProgress = BeginnerProgress(completedPuzzleIDs: Set(loadedIDs))
        self.subject = CurrentValueSubject(initialProgress)
    }
    
    public var progressPublisher: AnyPublisher<BeginnerProgress, Never> {
        subject.eraseToAnyPublisher()
    }
    
    public var currentProgress: BeginnerProgress {
        subject.value
    }
    
    public func markCompleted(puzzleID: String) {
        var current = subject.value.completedPuzzleIDs
        current.insert(puzzleID)
        
        let newProgress = BeginnerProgress(completedPuzzleIDs: current)
        subject.send(newProgress)
        
        userDefaults.set(Array(current), forKey: key)
    }
    
    public func clearProgress() {
        userDefaults.removeObject(forKey: key)
        subject.send(BeginnerProgress(completedPuzzleIDs: []))
    }
}
