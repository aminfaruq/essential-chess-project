//
//  UserDefaultsThemeStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public final class UserDefaultsThemeStore: ThemeStore {
    private let store: UserDefaults
    private let cacheKey = "theme_settings_cache"
    
    public init(store: UserDefaults = .standard) {
        self.store = store
    }
    
    public func retrieve(completion: @escaping (ThemeStore.RetrievalResult) -> Void) {
        guard let data = store.data(forKey: cacheKey) else {
            return completion(.success(nil))
        }
        
        do {
            let settings = try JSONDecoder().decode(ThemeSettings.self, from: data)
            completion(.success(settings))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func insert(_ settings: ThemeSettings, completion: @escaping (ThemeStore.InsertionResult) -> Void) {
        do {
            let data = try JSONEncoder().encode(settings)
            store.set(data, forKey: cacheKey)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
