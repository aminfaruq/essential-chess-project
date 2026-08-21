//
//  SettingsViewModelTests.swift
//  EssentialChessUITests
//

import XCTest
import EssentialChess
@testable import EssentialChessUI

@MainActor
final class SettingsViewModelTests: XCTestCase {

    // MARK: - Init Tests

    func test_init_readsInitialReminderStateFromStorage() {
        let (sut, _, _, _) = makeSUT(initialReminderState: true)

        XCTAssertTrue(sut.isDailyReminderEnabled)
    }

    func test_init_readsInitialHapticFromStorage() {
        let (sut, _, _, _) = makeSUT(initialHaptic: false, initialSound: true)

        XCTAssertFalse(sut.isHapticEnabled)
    }

    func test_init_readsInitialSoundFromStorage() {
        let (sut, _, _, _) = makeSUT(initialHaptic: true, initialSound: false)

        XCTAssertFalse(sut.isSoundEnabled)
    }

    // MARK: - setDailyReminder Tests

    func test_userEnablesDailyReminder_promptsPermissionAndSchedulesFor8AM() {
        let (sut, storage, scheduler, _) = makeSUT(initialReminderState: false)
        scheduler.permissionToGrant = true

        sut.setDailyReminder(enabled: true)

        XCTAssertEqual(scheduler.requestPermissionCallCount, 1)
        XCTAssertEqual(scheduler.scheduledReminders.count, 1)

        let reminder = scheduler.scheduledReminders.first
        XCTAssertEqual(reminder?.hour, 8)
        XCTAssertEqual(reminder?.minute, 0)
        XCTAssertEqual(reminder?.title, "Time to Practice! ♟️")
        XCTAssertTrue(reminder?.body.contains("daily puzzles") ?? false)

        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertTrue(storage.isDailyReminderEnabled)
            XCTAssertTrue(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_userEnablesDailyReminder_whenPermissionDenied_doesNotSchedule() {
        let (sut, storage, scheduler, _) = makeSUT(initialReminderState: false)
        scheduler.permissionToGrant = false

        sut.setDailyReminder(enabled: true)

        XCTAssertEqual(scheduler.requestPermissionCallCount, 1)
        XCTAssertEqual(scheduler.scheduledReminders.count, 0)

        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertFalse(storage.isDailyReminderEnabled)
            XCTAssertFalse(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_userDisablesDailyReminder_cancelsPendingNotifications() {
        let (sut, storage, scheduler, _) = makeSUT(initialReminderState: true)

        sut.setDailyReminder(enabled: false)

        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 1)

        let exp = expectation(description: "Wait for async update")
        DispatchQueue.main.async {
            XCTAssertFalse(storage.isDailyReminderEnabled)
            XCTAssertFalse(sut.isDailyReminderEnabled)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }

    func test_setDailyReminder_enableWhenAlreadyEnabled_doesNothing() {
        let (sut, _, scheduler, _) = makeSUT(initialReminderState: true)

        sut.setDailyReminder(enabled: true)

        XCTAssertEqual(scheduler.requestPermissionCallCount, 0)
        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 0)
    }

    func test_setDailyReminder_disableWhenAlreadyDisabled_doesNothing() {
        let (sut, _, scheduler, _) = makeSUT(initialReminderState: false)

        sut.setDailyReminder(enabled: false)

        XCTAssertEqual(scheduler.requestPermissionCallCount, 0)
        XCTAssertEqual(scheduler.cancelDailyReminderCallCount, 0)
    }

    // MARK: - setHaptic Tests

    func test_setHaptic_enabledTrue_toFalse_updatesStorage() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: true, initialSound: true)

        sut.setHaptic(enabled: false)

        XCTAssertFalse(sut.isHapticEnabled)
        XCTAssertFalse(boardStorage.isHapticEnabled)
    }

    func test_setHaptic_enabledFalse_toTrue_updatesStorage() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: false, initialSound: true)

        sut.setHaptic(enabled: true)

        XCTAssertTrue(sut.isHapticEnabled)
        XCTAssertTrue(boardStorage.isHapticEnabled)
    }

    func test_setHaptic_sameValue_doesNothing() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: true, initialSound: true)

        sut.setHaptic(enabled: true)

        XCTAssertTrue(sut.isHapticEnabled)
        XCTAssertTrue(boardStorage.isHapticEnabled)
    }

    // MARK: - setSound Tests

    func test_setSound_enabledTrue_toFalse_updatesStorage() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: true, initialSound: true)

        sut.setSound(enabled: false)

        XCTAssertFalse(sut.isSoundEnabled)
        XCTAssertFalse(boardStorage.isSoundEnabled)
    }

    func test_setSound_enabledFalse_toTrue_updatesStorage() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: true, initialSound: false)

        sut.setSound(enabled: true)

        XCTAssertTrue(sut.isSoundEnabled)
        XCTAssertTrue(boardStorage.isSoundEnabled)
    }

    func test_setSound_sameValue_doesNothing() {
        let (sut, _, _, boardStorage) = makeSUT(initialHaptic: true, initialSound: true)

        sut.setSound(enabled: true)

        XCTAssertTrue(sut.isSoundEnabled)
        XCTAssertTrue(boardStorage.isSoundEnabled)
    }

    // MARK: - resetProgress Tests

    func test_resetProgress_triggersOnResetProgressCallback() {
        var resetCallCount = 0
        let (sut, _, _, _) = makeSUT(onResetProgress: {
            resetCallCount += 1
        })

        sut.resetProgress()

        XCTAssertEqual(resetCallCount, 1)
    }

    // MARK: - Helpers

    private func makeSUT(
        initialReminderState: Bool = false,
        initialHaptic: Bool = true,
        initialSound: Bool = true,
        onResetProgress: (() -> Void)? = nil
    ) -> (sut: SettingsViewModel, storage: NotificationStoragePortSpy, scheduler: NotificationSchedulerSpy, boardStorage: BoardSettingsStoragePortSpy) {
        let storage = NotificationStoragePortSpy()
        storage.isDailyReminderEnabled = initialReminderState
        let scheduler = NotificationSchedulerSpy()
        let boardSettingsStorage = BoardSettingsStoragePortSpy()
        boardSettingsStorage.isHapticEnabled = initialHaptic
        boardSettingsStorage.isSoundEnabled = initialSound

        let sut = SettingsViewModel(
            notificationStorage: storage,
            notificationScheduler: scheduler,
            boardSettingsStorage: boardSettingsStorage,
            onResetProgress: onResetProgress
        )

        trackForMemoryLeaks(sut)
        trackForMemoryLeaks(storage)
        trackForMemoryLeaks(scheduler)
        trackForMemoryLeaks(boardSettingsStorage)

        return (sut, storage, scheduler, boardSettingsStorage)
    }
}

// MARK: - Spies

class NotificationStoragePortSpy: NotificationStore {
    var isDailyReminderEnabled: Bool = false
    var readCallCount = 0
}

class BoardSettingsStoragePortSpy: BoardSettingsStore {
    var isHapticEnabled: Bool = true {
        didSet { hapticWriteCount += 1 }
    }
    var isSoundEnabled: Bool = true {
        didSet { soundWriteCount += 1 }
    }
    var hapticWriteCount = 0
    var soundWriteCount = 0
}

@MainActor
class NotificationSchedulerSpy: NotificationSchedulerLoader {
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

    func requestPermission(completion: @escaping @MainActor (Bool) -> Void) {
        requestPermissionCallCount += 1
        completion(permissionToGrant)
    }

    func scheduleDailyReminder(hour: Int, minute: Int, title: String, body: String, completion: @escaping @MainActor (Error?) -> Void) {
        scheduledReminders.append(ScheduledReminder(hour: hour, minute: minute, title: title, body: body))
        completion(nil)
    }

    func cancelDailyReminder() {
        cancelDailyReminderCallCount += 1
    }
}
