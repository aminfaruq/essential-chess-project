//
//  UserDefaultsBoardSettingsStorage.swift
//  EssentialChess
//

import Foundation

public final class UserDefaultsBoardSettingsStorage: BoardSettingsStoragePort {
    private let userDefaults: UserDefaults
    private let hapticKey = "isHapticEnabled"
    private let soundKey = "isSoundEnabled"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Register default values so they are true by default
        userDefaults.register(defaults: [
            hapticKey: true,
            soundKey: true
        ])
    }
    
    public var isHapticEnabled: Bool {
        get {
            return userDefaults.bool(forKey: hapticKey)
        }
        set {
            userDefaults.set(newValue, forKey: hapticKey)
        }
    }
    
    public var isSoundEnabled: Bool {
        get {
            return userDefaults.bool(forKey: soundKey)
        }
        set {
            userDefaults.set(newValue, forKey: soundKey)
        }
    }
}
