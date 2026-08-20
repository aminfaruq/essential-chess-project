//
//  BeginnerProgress.swift
//  EssentialChess
//
//  Created by Amin faruq on 07/07/26.
//

public struct BeginnerProgress: Hashable, Equatable {
    public let completedPuzzleIDs: Set<String>
    
    public init(completedPuzzleIDs: Set<String> = []) {
        self.completedPuzzleIDs = completedPuzzleIDs
    }
}
