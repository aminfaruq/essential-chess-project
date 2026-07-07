//
//  CurriculumProgressTracker.swift
//  EssentialChess
//
//  Created by Amin faruq on 10/06/26.
//

import Foundation

public struct CurriculumProgressCalculator {
    // MARK: - Constants
    
    private static let examCooldown: TimeInterval = 3 * 3600 // 3 hours
    
    // MARK: - Section Unlock Logic
    
    public static func isSectionUnlocked(_ section: EloSection, progress: UserProgress) -> Bool {
        if !section.isLockedByDefault {
            return true
        }
        return progress.hiddenRating >= section.eloFloor
    }
    
    // MARK: - Progress Calculations
    
    public static func progress(for subTheme: SubTheme, progress: UserProgress) -> Double {
        guard subTheme.totalPuzzles > 0 else { return 0.0 }
        
        let completedCount = subTheme.puzzles.filter { puzzle in
            progress.completedPuzzleIDs.contains(puzzle.id)
        }.count
        
        return Double(completedCount) / Double(subTheme.totalPuzzles)
    }
    
    public static func progress(for category: Category, progress: UserProgress) -> Double {
        guard let themes = category.subThemes, !themes.isEmpty else { return 0.0 }
        
        let total = themes.reduce(0) { $0 + $1.totalPuzzles }
        let completed = themes.reduce(0) { currentSum, theme in
            let completedInTheme = theme.puzzles.filter { progress.completedPuzzleIDs.contains($0.id) }.count
            return currentSum + completedInTheme
        }
        
        return total > 0 ? Double(completed) / Double(total) : 0.0
    }
    
    public static func progress(for section: EloSection, progress: UserProgress) -> Double {
        let examCategory = section.categories.first { $0.isExamMode }
        
        if let examID = examCategory?.id, progress.passedExamIDs.contains(examID) {
            return 1.0 // Fully completed
        }
        
        let nonExamCategories = section.categories.filter { !$0.isExamMode }
        guard !nonExamCategories.isEmpty else { return 0.0 }
        
        let total = nonExamCategories.flatMap { $0.subThemes ?? [] }.reduce(0) { $0 + $1.totalPuzzles }
        let completed = nonExamCategories
            .flatMap { $0.subThemes ?? [] }
            .flatMap { $0.puzzles }
            .filter { progress.completedPuzzleIDs.contains($0.id) }
            .count
        
        guard total > 0 else { return 0.0 }
        
        // Cap at 99% if the exam is not passed yet
        return min(0.99, Double(completed) / Double(total))
    }
    
    // MARK: - Exam Logic
    
    public static func isExamUnlocked(for section: EloSection, progress: UserProgress) -> Bool {
        let nonExamCategories = section.categories.filter { !$0.isExamMode }
        guard !nonExamCategories.isEmpty else { return false }
        
        let total = nonExamCategories.flatMap { $0.subThemes ?? [] }.reduce(0) { $0 + $1.totalPuzzles }
        let completed = nonExamCategories
            .flatMap { $0.subThemes ?? [] }
            .flatMap { $0.puzzles }
            .filter { progress.completedPuzzleIDs.contains($0.id) }
            .count
        
        return total > 0 && completed >= total
    }
    
    // MARK: - Exam Cooldown Logic
    
    public static func canStartExam(categoryID: String, progress: UserProgress, currentDate: Date = Date()) -> Bool {
        guard let failTime = progress.examFailureTimes[categoryID] else { return true }
        return currentDate.timeIntervalSince(failTime) >= examCooldown
    }
    
    public static func remainingCooldown(categoryID: String, progress: UserProgress, currentDate: Date = Date()) -> TimeInterval {
        guard let failTime = progress.examFailureTimes[categoryID] else { return 0.0 }
        return max(0.0, examCooldown - currentDate.timeIntervalSince(failTime))
    }
}
