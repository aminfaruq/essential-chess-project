//
//  BeginnerProgressStore.swift
//  EssentialChess
//
//  Created by Amin faruq on 07/07/26.
//

import Combine

public protocol BeginnerProgressStore {
    var progressPublisher: AnyPublisher<BeginnerProgress, Never> { get }
    var currentProgress: BeginnerProgress { get }
    
    func markCompleted(puzzleID: String)
    func clearProgress()
}
