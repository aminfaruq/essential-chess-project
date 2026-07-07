//
//  StreakViewModelTests.swift
//  EssentialChessUITests
//
//  Created by Amin faruq on 14/06/26.
//

import XCTest
import Combine
import EssentialChess
@testable import EssentialChessUI

final class StreakViewModelTests: XCTestCase {

    func test_init_setsInitialValues() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.streakCount, 0)
        XCTAssertFalse(sut.isStreakActiveToday)
    }
    
    func test_progressUpdate_updatesStreakCountOnMainThread() {
        let (sut, subject) = makeSUT()
        
        let exp = expectation(description: "Wait for main thread")
        let progress = UserProgress(currentStreak: 5, lastActivityDate: nil)
        
        subject.send(progress)
        
        DispatchQueue.main.async {
            XCTAssertEqual(sut.streakCount, 5)
            XCTAssertFalse(sut.isStreakActiveToday)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_progressUpdate_withLastActivityToday_setsStreakActiveTodayToTrue() {
        let (sut, subject) = makeSUT()
        
        let exp = expectation(description: "Wait for main thread")
        let today = Date()
        let progress = UserProgress(currentStreak: 2, lastActivityDate: today)
        
        subject.send(progress)
        
        DispatchQueue.main.async {
            XCTAssertEqual(sut.streakCount, 2)
            XCTAssertTrue(sut.isStreakActiveToday)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_progressUpdate_withLastActivityYesterday_setsStreakActiveTodayToFalse() {
        let (sut, subject) = makeSUT()
        
        let exp = expectation(description: "Wait for main thread")
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let progress = UserProgress(currentStreak: 3, lastActivityDate: yesterday)
        
        subject.send(progress)
        
        DispatchQueue.main.async {
            XCTAssertEqual(sut.streakCount, 3)
            XCTAssertFalse(sut.isStreakActiveToday)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: StreakViewModel, subject: PassthroughSubject<UserProgress, Never>) {
        let subject = PassthroughSubject<UserProgress, Never>()
        let sut = StreakViewModel(progressPublisher: subject.eraseToAnyPublisher())
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(subject, file: file, line: line)
        
        return (sut, subject)
    }
}
