//
//  KeyValueStore.swift
//  EssentialChess
//

import Foundation

public protocol KeyValueStore {
    func data(forKey defaultName: String) -> Data?
    func set(_ value: Any?, forKey defaultName: String)
    func removeObject(forKey defaultName: String)
    @discardableResult func synchronize() -> Bool
}

extension UserDefaults: KeyValueStore {}

extension NSUbiquitousKeyValueStore: KeyValueStore {}
