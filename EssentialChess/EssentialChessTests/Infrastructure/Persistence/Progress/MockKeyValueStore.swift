//
//  MockKeyValueStore.swift
//  EssentialChessTests
//

import Foundation
import EssentialChess

class MockKeyValueStore: KeyValueStore {
    var store: [String: Data] = [:]
    var syncCallCount = 0
    var removedKeys: [String] = []
    
    func data(forKey defaultName: String) -> Data? {
        return store[defaultName]
    }
    
    func set(_ value: Any?, forKey defaultName: String) {
        if let data = value as? Data {
            store[defaultName] = data
        } else {
            store.removeValue(forKey: defaultName)
        }
    }
    
    func removeObject(forKey defaultName: String) {
        store.removeValue(forKey: defaultName)
        removedKeys.append(defaultName)
    }
    
    @discardableResult
    func synchronize() -> Bool {
        syncCallCount += 1
        return true
    }
}
