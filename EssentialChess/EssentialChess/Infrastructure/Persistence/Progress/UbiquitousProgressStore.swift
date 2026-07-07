//
//  UbiquitousProgressStore.swift
//  EssentialChess
//

import Foundation

public final class UbiquitousProgressStore: ProgressLoader {
    private let store: KeyValueStore
    private let localStore: KeyValueStore
    private let cacheKey = "user_progress_cache"
    
    public init(store: KeyValueStore = NSUbiquitousKeyValueStore.default, localStore: KeyValueStore = UserDefaults.standard) {
        self.store = store
        self.localStore = localStore
    }
    
    public func retrieve(completion: @escaping (ProgressLoader.RetrievalResult) -> Void) {
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
    
    public func insert(_ progress: UserProgress, completion: @escaping (ProgressLoader.InsertionResult) -> Void) {
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
    
    private func decode(_ data: Data, completion: @escaping (ProgressLoader.RetrievalResult) -> Void) {
        do {
            let cache = try JSONDecoder().decode(ProgressCacheDTO.self, from: data)
            completion(.success(cache.toModel()))
        } catch {
            completion(.failure(error))
        }
    }
}
