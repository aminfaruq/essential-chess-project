//
//  CurriculumProgressTracker.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct CurriculumProgressTracker {
    
    // MARK: - Section Logic
    
    public static func isSectionUnlocked(_ section: EloSection, progress: UserProgress) -> Bool {
        if !section.isLockedByDefault {
            return true
        }
        return progress.hiddenRating >= section.eloFloor
    }
    
    // MARK: - SubTheme Logic
    
    public static func progress(for subTheme: SubTheme, progress: UserProgress) -> Double {
        guard subTheme.totalPuzzles > 0 else { return 0.0 }
        
        let completedCount = subTheme.puzzles.filter { puzzle in
            progress.completedPuzzleIDs.contains(puzzle.id)
        }.count
        
        return Double(completedCount) / Double(subTheme.totalPuzzles)
    }
}
