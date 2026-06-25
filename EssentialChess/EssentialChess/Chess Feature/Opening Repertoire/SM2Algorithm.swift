//
//  SM2Algorithm.swift
//  EssentialChess
//

import Foundation

public final class SM2Algorithm {
    public struct Result: Equatable {
        public let interval: Int
        public let repetitions: Int
        public let easeFactor: Double
        public let nextReviewDate: Date
    }
    
    public init() {}
    
    /// Calculates the next spaced repetition scheduling variables using the SM-2 algorithm.
    /// - Parameters:
    ///   - quality: 0 to 5 (5: perfect, 4: correct with hesitation, 3: correct with difficulty, 2: incorrect but easy to recall, 1: incorrect but remembered, 0: complete blackout).
    ///   - repetitions: Number of consecutive correct answers.
    ///   - previousInterval: The interval before the current review (in days).
    ///   - previousEaseFactor: The previous ease factor (minimum 1.3).
    ///   - currentDate: The date of the review (defaults to now).
    /// - Returns: The calculated Result containing updated values.
    public static func calculate(
        quality: Int,
        repetitions: Int,
        previousInterval: Int,
        previousEaseFactor: Double,
        currentDate: Date = Date()
    ) -> Result {
        let q = Double(max(0, min(5, quality)))
        var easeFactor = previousEaseFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        easeFactor = max(1.3, easeFactor)
        
        var nextRepetitions = repetitions
        var nextInterval = previousInterval
        
        if quality < 3 {
            nextRepetitions = 0
            nextInterval = 1
        } else {
            nextRepetitions += 1
            if nextRepetitions == 1 {
                nextInterval = 1
            } else if nextRepetitions == 2 {
                nextInterval = 6
            } else {
                nextInterval = Int(round(Double(previousInterval) * easeFactor))
            }
        }
        
        let nextDate = Calendar.current.date(byAdding: .day, value: nextInterval, to: currentDate) ?? currentDate
        
        return Result(
            interval: nextInterval,
            repetitions: nextRepetitions,
            easeFactor: easeFactor,
            nextReviewDate: nextDate
        )
    }
}
