//
//  UserDefaultsNotificationStorage.swift
//  EssentialChess
//

import Foundation

public final class UserDefaultsNotificationStorage: NotificationStore {
    private let userDefaults: UserDefaults
    private let key = "isDailyReminderEnabled"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public var isDailyReminderEnabled: Bool {
        get {
            return userDefaults.bool(forKey: key)
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}
