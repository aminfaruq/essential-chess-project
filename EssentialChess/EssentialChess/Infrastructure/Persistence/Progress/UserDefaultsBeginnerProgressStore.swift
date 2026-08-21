import Foundation

public final class UserDefaultsBeginnerProgressStore: BeginnerProgressStore {
    private let userDefaults: UserDefaults
    private let key: String
    private var _progress: BeginnerProgress
    
    public init(userDefaults: UserDefaults = .standard, key: String = "beginner_completed_puzzles") {
        self.userDefaults = userDefaults
        self.key = key
        
        let loadedIDs = userDefaults.stringArray(forKey: key) ?? []
        self._progress = BeginnerProgress(completedPuzzleIDs: Set(loadedIDs))
    }
    
    public var currentProgress: BeginnerProgress {
        _progress
    }
    
    public func markCompleted(puzzleID: String) {
        var current = _progress.completedPuzzleIDs
        current.insert(puzzleID)
        
        _progress = BeginnerProgress(completedPuzzleIDs: current)
        userDefaults.set(Array(current), forKey: key)
    }
    
    public func clearProgress() {
        userDefaults.removeObject(forKey: key)
        _progress = BeginnerProgress(completedPuzzleIDs: [])
    }
}
