//
//  UserDefaultsProgressLoader.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public final class UserDefaultsProgressLoader: ProgressLoader {
    private let store: KeyValueStore
    private let cacheKey = "user_progress_cache"
    
    public init(store: KeyValueStore = UserDefaults.standard) {
        self.store = store
    }
    
    public func retrieve(completion: @escaping (ProgressLoader.RetrievalResult) -> Void) {
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
    
    public func insert(_ progress: UserProgress, completion: @escaping (ProgressLoader.InsertionResult) -> Void) {
        do {
            let cache = ProgressCacheDTO(from: progress)
            let data = try JSONEncoder().encode(cache)
            store.set(data, forKey: cacheKey)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
