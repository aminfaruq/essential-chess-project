//
//  BoardSettingsStore.swift
//  EssentialChess
//

import Foundation

public protocol BoardSettingsStore {
    var isHapticEnabled: Bool { get set }
    var isSoundEnabled: Bool { get set }
}
