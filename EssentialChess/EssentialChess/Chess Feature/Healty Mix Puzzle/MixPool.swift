//
//  MixPool.swift
//  EssentialChess
//
//  Created by Amin faruq on 09/06/26.
//

import Foundation

public struct MixPool: Equatable {
    public let id: String
    public let metadata: MixPoolMetadata
    public let difficultyTiers: [DifficultyTier]
    
    public init(id: String, metadata: MixPoolMetadata, difficultyTiers: [DifficultyTier]) {
        self.id = id
        self.metadata = metadata
        self.difficultyTiers = difficultyTiers
    }
}

public struct MixPoolMetadata: Equatable {
    public let totalPuzzles: Int
    public let supportedModes: [String]
    
    public init(totalPuzzles: Int, supportedModes: [String]) {
        self.totalPuzzles = totalPuzzles
        self.supportedModes = supportedModes
    }
}

public struct DifficultyTier: Equatable {
    public let id: String
    public let displayName: String
    public let eloRange: String
    public let accentColorHex: String
    public let description: String
    public let puzzles: [Puzzle] // Reusing the Puzzle entity!
    
    public init(id: String, displayName: String, eloRange: String, accentColorHex: String, description: String, puzzles: [Puzzle]) {
        self.id = id
        self.displayName = displayName
        self.eloRange = eloRange
        self.accentColorHex = accentColorHex
        self.description = description
        self.puzzles = puzzles
    }
}
