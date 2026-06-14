//
//  UserProgressDailyStreakTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class UserProgressDailyStreakTests: XCTestCase {
    
    // MARK: - Scenario: First time completing a session
    
    func test_recordActivity_withNoExistingStreak_setsStreakToOneAndUpdatesDate() {
        let now = Date()
        var sut = UserProgress(currentStreak: 0, lastActivityDate: nil)
        
        sut.recordActivity(at: now)
        
        XCTAssertEqual(sut.currentStreak, 1)
        XCTAssertEqual(sut.lastActivityDate, now)
    }
    
    // MARK: - Scenario: Completing a session on the same day
    
    func test_recordActivity_onSameDay_keepsStreakAndUpdatesDate() {
        let calendar = Calendar.current
        let today = Date(timeIntervalSince1970: 100000)
        let laterToday = today.addingTimeInterval(3600) // 1 hour later on the same day
        var sut = UserProgress(currentStreak: 3, lastActivityDate: today)
        
        sut.recordActivity(at: laterToday, calendar: calendar)
        
        XCTAssertEqual(sut.currentStreak, 3)
        XCTAssertEqual(sut.lastActivityDate, laterToday)
    }
    
    // MARK: - Scenario: Completing a session on the next consecutive day
    
    func test_recordActivity_onNextConsecutiveDay_incrementsStreakAndUpdatesDate() {
        let calendar = Calendar.current
        let today = Date(timeIntervalSince1970: 100000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        var sut = UserProgress(currentStreak: 3, lastActivityDate: yesterday)
        
        sut.recordActivity(at: today, calendar: calendar)
        
        XCTAssertEqual(sut.currentStreak, 4)
        XCTAssertEqual(sut.lastActivityDate, today)
    }
    
    // MARK: - Scenario: Missing a day (Streak broken)
    
    func test_recordActivity_missingADay_resetsStreakToOneAndUpdatesDate() {
        let calendar = Calendar.current
        let today = Date(timeIntervalSince1970: 100000)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        var sut = UserProgress(currentStreak: 5, lastActivityDate: twoDaysAgo)
        
        sut.recordActivity(at: today, calendar: calendar)
        
        XCTAssertEqual(sut.currentStreak, 1)
        XCTAssertEqual(sut.lastActivityDate, today)
    }
}
