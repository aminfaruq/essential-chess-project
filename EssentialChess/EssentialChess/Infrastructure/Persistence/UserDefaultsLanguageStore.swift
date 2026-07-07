//
//  UserDefaultsLanguageStore.swift
//  EssentialChess
//

import Foundation

public final class UserDefaultsLanguageStore: LanguageStore {
    private let userDefaults: UserDefaults
    private let key = "app_language_code"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public var languageCode: String {
        get {
            return userDefaults.string(forKey: key) ?? "en"
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}
