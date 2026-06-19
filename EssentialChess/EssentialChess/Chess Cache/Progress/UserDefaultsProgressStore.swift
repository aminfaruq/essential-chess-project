//
//  UserDefaultsProgressStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public final class UserDefaultsProgressStore: ProgressStore {
    private let store: UserDefaults
    private let cacheKey = "user_progress_cache"
    
    public init(store: UserDefaults = .standard) {
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
                highestPuzzleStreak: highestPuzzleStreak ?? 0,
                highestPuzzleStorm: highestPuzzleStorm ?? 0
            )
        }
    }
}
