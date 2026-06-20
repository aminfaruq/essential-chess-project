//
//  UbiquitousProgressStore.swift
//  EssentialChess
//

import Foundation

public final class UbiquitousProgressStore: ProgressStore {
    private let store: NSUbiquitousKeyValueStore
    private let localStore: UserDefaults
    private let cacheKey = "user_progress_cache"
    
    public init(store: NSUbiquitousKeyValueStore = .default, localStore: UserDefaults = .standard) {
        self.store = store
        self.localStore = localStore
    }
    
    public func retrieve(completion: @escaping (ProgressStore.RetrievalResult) -> Void) {
        if let data = store.data(forKey: cacheKey) {
            decode(data, completion: completion)
        } else {
            // Attempt migration from localStore
            if let localData = localStore.data(forKey: cacheKey) {
                // Save to ubiquitous store to complete migration
                store.set(localData, forKey: cacheKey)
                store.synchronize()
                
                // Clear localStore to avoid duplicate data (optional)
                localStore.removeObject(forKey: cacheKey)
                
                decode(localData, completion: completion)
            } else {
                completion(.success(nil))
            }
        }
    }
    
    public func insert(_ progress: UserProgress, completion: @escaping (ProgressStore.InsertionResult) -> Void) {
        do {
            let cache = ProgressCacheDTO(from: progress)
            let data = try JSONEncoder().encode(cache)
            store.set(data, forKey: cacheKey)
            store.synchronize()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    private func decode(_ data: Data, completion: @escaping (ProgressStore.RetrievalResult) -> Void) {
        do {
            let cache = try JSONDecoder().decode(ProgressCacheDTO.self, from: data)
            completion(.success(cache.toModel()))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - DTO (Data Transfer Object)
    
    private struct ProgressCacheDTO: Codable {
        let hiddenRating: Double
        let actualRating: Double?
        let onboardingComplete: Bool
        let completedPuzzleIDs: Set<String>
        let passedExamIDs: Set<String>
        let examFailureTimes: [String: Date]
        let currentStreak: Int
        let lastActivityDate: Date?
        let isPro: Bool?
        let dailyPuzzleMixCount: Int?
        let lastPuzzleMixDate: Date?
        let dailyPuzzleStreakCount: Int?
        let lastPuzzleStreakDate: Date?
        let activePuzzleStreak: Int?
        let activePuzzleStreakUsedIDs: Set<String>?
        let highestPuzzleStreak: Int?
        let highestPuzzleStorm: Int?
        
        init(from model: UserProgress) {
            self.hiddenRating = model.hiddenRating
            self.actualRating = model.actualRating
            self.onboardingComplete = model.onboardingComplete
            self.completedPuzzleIDs = model.completedPuzzleIDs
            self.passedExamIDs = model.passedExamIDs
            self.examFailureTimes = model.examFailureTimes
            self.currentStreak = model.currentStreak
            self.lastActivityDate = model.lastActivityDate
            self.isPro = model.isPro
            self.dailyPuzzleMixCount = model.dailyPuzzleMixCount
            self.lastPuzzleMixDate = model.lastPuzzleMixDate
            self.dailyPuzzleStreakCount = model.dailyPuzzleStreakCount
            self.lastPuzzleStreakDate = model.lastPuzzleStreakDate
            self.activePuzzleStreak = model.activePuzzleStreak
            self.activePuzzleStreakUsedIDs = model.activePuzzleStreakUsedIDs
            self.highestPuzzleStreak = model.highestPuzzleStreak
            self.highestPuzzleStorm = model.highestPuzzleStorm
        }
        
        func toModel() -> UserProgress {
            UserProgress(
                hiddenRating: hiddenRating,
                actualRating: actualRating,
                onboardingComplete: onboardingComplete,
                completedPuzzleIDs: completedPuzzleIDs,
                passedExamIDs: passedExamIDs,
                examFailureTimes: examFailureTimes,
                currentStreak: currentStreak,
                lastActivityDate: lastActivityDate,
                isPro: isPro ?? false,
                dailyPuzzleMixCount: dailyPuzzleMixCount ?? 0,
                lastPuzzleMixDate: lastPuzzleMixDate,
                dailyPuzzleStreakCount: dailyPuzzleStreakCount ?? 0,
                lastPuzzleStreakDate: lastPuzzleStreakDate,
                activePuzzleStreak: activePuzzleStreak ?? 0,
                activePuzzleStreakUsedIDs: activePuzzleStreakUsedIDs ?? [],
                highestPuzzleStreak: highestPuzzleStreak ?? 0,
                highestPuzzleStorm: highestPuzzleStorm ?? 0
            )
        }
    }
}
