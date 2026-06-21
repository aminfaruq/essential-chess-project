//
//  UserDefaultsProgressStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public final class UserDefaultsProgressStore: ProgressStore {
    private let store: KeyValueStore
    private let cacheKey = "user_progress_cache"
    
    public init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
    }
    
    public func retrieve(completion: @escaping (ProgressStore.RetrievalResult) -> Void) {
        guard let data = store.data(forKey: cacheKey) else {
            return completion(.success(nil))
        }
        
        do {
            let cache = try JSONDecoder().decode(ProgressCacheDTO.self, from: data)
            completion(.success(cache.toModel()))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func insert(_ progress: UserProgress, completion: @escaping (ProgressStore.InsertionResult) -> Void) {
        do {
            let cache = ProgressCacheDTO(from: progress)
            let data = try JSONEncoder().encode(cache)
            store.set(data, forKey: cacheKey)
            completion(.success(()))
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
        let dailyPuzzleStormCount: Int?
        let lastPuzzleStormDate: Date?
        
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
            self.dailyPuzzleStormCount = model.dailyPuzzleStormCount
            self.lastPuzzleStormDate = model.lastPuzzleStormDate
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
                highestPuzzleStorm: highestPuzzleStorm ?? 0,
                dailyPuzzleStormCount: dailyPuzzleStormCount ?? 0,
                lastPuzzleStormDate: lastPuzzleStormDate
            )
        }
    }
}
