//
//  UserProgress+DailyStreak.swift
//  EssentialChess
//
//  Created by Amin faruq on 14/06/26.
//

import Foundation

extension UserProgress {
    /// Evaluates and updates the streak based on the current date.
    /// Call this function WHENEVER the user successfully completes a puzzle/exam.
    public mutating func recordActivity(at currentDate: Date = Date(), calendar: Calendar = .current) {
        guard let lastDate = lastActivityDate else {
            // First time ever playing
            currentStreak = 1
            lastActivityDate = currentDate
            return
        }
        
        if calendar.isDate(currentDate, inSameDayAs: lastDate) {
            // Played again on the same day: Do nothing to the streak count
            lastActivityDate = currentDate
        } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: currentDate), calendar.isDate(lastDate, inSameDayAs: yesterday) {
            // Played on the next consecutive day: Increment streak
            currentStreak += 1
            lastActivityDate = currentDate
        } else {
            // Missed a day (or more): Reset streak
            currentStreak = 1
            lastActivityDate = currentDate
        }
    }
}
