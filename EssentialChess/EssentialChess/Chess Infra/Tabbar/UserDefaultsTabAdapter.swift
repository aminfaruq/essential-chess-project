//
//  UserDefaultsTabAdapter.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//
import Foundation

public final class UserDefaultsTabAdapter: TabStoragePort {
    private let storageKey = "selectedAppTab"
    private let defaults: UserDefaults
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }
    
    public var savedTab: AppTab {
        get {
            guard let rawValue = defaults.string(forKey: storageKey),
                  let tab = AppTab(rawValue: rawValue) else {
                return .curriculum
            }
            return tab
        }
        set {
            defaults.set(newValue.rawValue, forKey: storageKey)
        }
    }
}
