//
//  SettingsViewModelTests.swift
//  EssentialChessUITests
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

final class SettingsViewModelTests: XCTestCase {

    // MARK: - Scenario: User enables the daily reminder for the first time
    func test_userEnablesDailyReminder_promptsPermissionAndSchedulesFor8AM() {
        // Given the user navigates to the "Settings" view
        let (sut, storage, scheduler) = makeSUT(initialReminderState: false)
        scheduler.permissionToGrant = true
        
        // When the user taps the "Enable Daily Reminder" toggle
        sut.setDailyReminder(enabled: true)
        
        // Then the system must prompt the iOS permission dialog
        XCTAssertEqual(scheduler.requestPermissionCallCount, 1, "Expected permission to be requested")
        
        // And upon the user granting permission
        // Then the system must automatically schedule the reminder for 8:00 AM.
        // Scenario: System strictly schedules the notification for 8:00 AM
        XCTAssertEqual(scheduler.scheduledReminders.count, 1)
        
        let reminder = scheduler.scheduledReminders.first
        XCTAssertEqual(reminder?.hour, 8)
        XCTAssertEqual(reminder?.minute, 0)
        XCTAssertEqual(reminder?.title, "Time to Practice! ♟️")
        XCTAssertTrue(reminder?.body.contains("daily puzzles") ?? false)
        
        // Ensure storage is updated
        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertTrue(storage.isDailyReminderEnabled)
            XCTAssertTrue(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_userEnablesDailyReminder_whenPermissionDenied_doesNotSchedule() {
        let (sut, storage, scheduler) = makeSUT(initialReminderState: false)
        scheduler.permissionToGrant = false // User denies permission
        
        sut.setDailyReminder(enabled: true)
        
        XCTAssertEqual(scheduler.requestPermissionCallCount, 1)
        XCTAssertEqual(scheduler.scheduledReminders.count, 0, "Should not schedule if permission denied")
        
        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertFalse(storage.isDailyReminderEnabled)
            XCTAssertFalse(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Scenario: User disables the daily reminder
    func test_userDisablesDailyReminder_cancelsPendingNotifications() {
        // Given the user has an active 8:00 AM daily reminder scheduled
        let (sut, storage, scheduler) = makeSUT(initialReminderState: true)
        
        // When the user taps the "Disable Reminder" toggle
        sut.setDailyReminder(enabled: false)
        
        // Then the system must call cancel
        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 1)
        
        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertFalse(storage.isDailyReminderEnabled)
            XCTAssertFalse(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    // MARK: - Helpers
    
    private func makeSUT(initialReminderState: Bool = false) -> (sut: SettingsViewModel, storage: NotificationStoragePortSpy, scheduler: NotificationSchedulerSpy) {
        let storage = NotificationStoragePortSpy()
        storage.isDailyReminderEnabled = initialReminderState
        let scheduler = NotificationSchedulerSpy()
        let boardSettingsStorage = BoardSettingsStoragePortSpy()
        let sut = SettingsViewModel(notificationStorage: storage, notificationScheduler: scheduler, boardSettingsStorage: boardSettingsStorage)
        
        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(storage)
        trackForMemoryLeaks(scheduler)
        trackForMemoryLeaks(boardSettingsStorage)
        
        return (sut, storage, scheduler)
    }
}

// MARK: - Spies

class NotificationStoragePortSpy: NotificationStore {
    var isDailyReminderEnabled: Bool = false
}

class BoardSettingsStoragePortSpy: BoardSettingsStore {
    var isHapticEnabled: Bool = true
    var isSoundEnabled: Bool = true
}

class NotificationSchedulerSpy: NotificationScheduler {
    var requestPermissionCallCount = 0
    var permissionToGrant = false
    
    struct ScheduledReminder {
        let hour: Int
        let minute: Int
        let title: String
        let body: String
    }
    var scheduledReminders: [ScheduledReminder] = []
    
    var cancelDailyReminderCallCount = 0
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        requestPermissionCallCount += 1
        completion(permissionToGrant)
    }
    
    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String) {
        scheduledReminders.append(ScheduledReminder(hour: hour, minute: minute, title: title, body: body))
    }
    
    func cancelDailyReminder() {
        cancelDailyReminderCallCount += 1
    }
}
