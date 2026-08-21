//
//  BeginnerProgressStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 07/07/26.
//

public protocol BeginnerProgressStore {
    var currentProgress: BeginnerProgress { get }
    
    func markCompleted(puzzleID: String)
    func clearProgress()
}
