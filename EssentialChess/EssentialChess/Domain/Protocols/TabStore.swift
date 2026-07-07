//
//  TabStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//

import Foundation

public enum AppTab: String, Hashable {
    case curriculum
    case puzzleMix
    case settings
}

// MARK: - Domain / Abstraction Layer
public protocol TabStore {
    var savedTab: AppTab { get set }
}
