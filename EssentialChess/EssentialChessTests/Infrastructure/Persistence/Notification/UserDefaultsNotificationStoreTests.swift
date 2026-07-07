//
//  UserDefaultsNotificationStoreTests.swift
//  EssentialChessTests
//

import XCTest
import EssentialChess

final class UserDefaultsNotificationStoreTests: XCTestCase {

    private let testSuiteName = "com.essentialchess.test.notificationstore"

    override func tearDown() {
        super.tearDown()
        UserDefaults().removePersistentDomain(forName: testSuiteName)
    }

    func test_isDailyReminderEnabled_deliversFalseByDefaultWhenStorageIsEmpty() {
        let (sut, _) = makeSUT()

        XCTAssertFalse(sut.isDailyReminderEnabled, "Expected default to be false when no data is saved.")
    }

    func test_isDailyReminderEnabled_deliversFalseWhenStorageHasNonBooleanValue() {
        let (sut, testDefaults) = makeSUT()
        testDefaults.set("not_a_bool", forKey: "isDailyReminderEnabled")

        XCTAssertFalse(sut.isDailyReminderEnabled, "Expected false when storage contains a non-boolean value.")
    }

    func test_isDailyReminderEnabled_deliversSavedValue() {
        let (sut, _) = makeSUT()

        sut.isDailyReminderEnabled = true
        XCTAssertTrue(sut.isDailyReminderEnabled, "Expected true immediately after saving.")

        sut.isDailyReminderEnabled = false
        XCTAssertFalse(sut.isDailyReminderEnabled, "Expected false immediately after saving.")
    }

    func test_isDailyReminderEnabled_persistsAcrossStoreInstances() {
        let (_, testDefaults) = makeSUT()
        let sut1 = UserDefaultsNotificationStore(userDefaults: testDefaults)
        sut1.isDailyReminderEnabled = true

        let sut2 = UserDefaultsNotificationStore(userDefaults: testDefaults)

        XCTAssertTrue(sut2.isDailyReminderEnabled, "Expected new instance to read persisted value.")
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: UserDefaultsNotificationStore, testDefaults: UserDefaults) {
        let testDefaults = UserDefaults(suiteName: testSuiteName)!
        testDefaults.removePersistentDomain(forName: testSuiteName)

        let sut = UserDefaultsNotificationStore(userDefaults: testDefaults)

        trackForMemoryLeaks(sut, file: file, line: line)

        addTeardownBlock { [weak testDefaults] in
            testDefaults?.removePersistentDomain(forName: "com.essentialchess.test.notificationstore")
        }

        return (sut, testDefaults)
    }
}
