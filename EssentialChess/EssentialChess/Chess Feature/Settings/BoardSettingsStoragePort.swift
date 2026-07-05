//
//  BoardSettingsStoragePort.swift
//  EssentialChess
//

import Foundation

public protocol BoardSettingsStoragePort {
    var isHapticEnabled: Bool { get set }
    var isSoundEnabled: Bool { get set }
}
